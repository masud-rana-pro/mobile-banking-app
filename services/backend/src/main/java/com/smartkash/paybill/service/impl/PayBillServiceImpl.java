package com.smartkash.paybill.service.impl;

import com.smartkash.auth.dto.request.VerifyPinRequest;
import com.smartkash.auth.dto.response.PinVerificationResponse;
import com.smartkash.auth.service.AuthService;
import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.idempotency.entity.IdempotencyKey;
import com.smartkash.idempotency.enums.IdempotencyOperationType;
import com.smartkash.idempotency.enums.IdempotencyStatus;
import com.smartkash.idempotency.service.IdempotencyKeyService;
import com.smartkash.ledger.entity.LedgerEntry;
import com.smartkash.ledger.enums.LedgerEntryType;
import com.smartkash.ledger.repository.LedgerEntryRepository;
import com.smartkash.notification.enums.NotificationType;
import com.smartkash.notification.service.TransactionAlertService;
import com.smartkash.paybill.dto.request.PayBillRequest;
import com.smartkash.paybill.dto.response.PayBillResponse;
import com.smartkash.paybill.service.PayBillService;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.transaction.entity.TransactionRecord;
import com.smartkash.transaction.enums.TransactionStatus;
import com.smartkash.transaction.enums.TransactionType;
import com.smartkash.transaction.repository.TransactionRecordRepository;
import com.smartkash.user.entity.User;
import com.smartkash.user.enums.UserStatus;
import com.smartkash.user.repository.UserRepository;
import com.smartkash.wallet.entity.Wallet;
import com.smartkash.wallet.enums.WalletStatus;
import com.smartkash.wallet.repository.WalletRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HexFormat;
import java.util.Map;
import java.util.UUID;

@Service
public class PayBillServiceImpl implements PayBillService {

    private static final int IDEMPOTENCY_EXPIRY_HOURS = 24;

    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final TransactionRecordRepository transactionRecordRepository;
    private final LedgerEntryRepository ledgerEntryRepository;
    private final IdempotencyKeyService idempotencyKeyService;
    private final AuthService authService;
    private final TransactionAlertService transactionAlertService;

    public PayBillServiceImpl(
            UserRepository userRepository,
            WalletRepository walletRepository,
            TransactionRecordRepository transactionRecordRepository,
            LedgerEntryRepository ledgerEntryRepository,
            IdempotencyKeyService idempotencyKeyService,
            AuthService authService,
            TransactionAlertService transactionAlertService
    ) {
        this.userRepository = userRepository;
        this.walletRepository = walletRepository;
        this.transactionRecordRepository = transactionRecordRepository;
        this.ledgerEntryRepository = ledgerEntryRepository;
        this.idempotencyKeyService = idempotencyKeyService;
        this.authService = authService;
        this.transactionAlertService = transactionAlertService;
    }

    @Override
    @Transactional
    public PayBillResponse payBill(JwtPrincipal principal, PayBillRequest request) {
        User user = currentUser(principal);
        ensureActiveUser(user);

        PinVerificationResponse pinVerification = authService.verifyPin(principal, new VerifyPinRequest(request.pin()));
        if (!pinVerification.verified()) {
            return failedResponse("PIN verification failed.", request);
        }

        IdempotencyKey idempotencyKey = reserveOrValidateIdempotency(user, request);
        if (idempotencyKey.getStatus() == IdempotencyStatus.COMPLETED) {
            return completedResponse(idempotencyKey, request);
        }

        Wallet wallet = walletRepository.findByUserIdForUpdate(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("User wallet was not found."));
        ensureActiveWallet(wallet);
        ensureSufficientBalance(wallet, request.amount());

        BigDecimal balanceAfter = wallet.debit(request.amount());
        String transactionReference = uniqueTransactionReference("PB");
        TransactionRecord transaction = transactionRecordRepository.save(new TransactionRecord(
                transactionReference,
                user,
                TransactionType.PAY_BILL,
                TransactionStatus.SUCCESS,
                request.amount(),
                null,
                description(request)
        ));
        ledgerEntryRepository.save(new LedgerEntry(
                wallet,
                user,
                transactionReference,
                null,
                LedgerEntryType.DEBIT,
                request.amount(),
                balanceAfter,
                "Pay Bill wallet debit"
        ));

        idempotencyKeyService.markCompleted(idempotencyKey, "SUCCESS:" + transactionReference + ":" + balanceAfter);
        transactionAlertService.sendTransactionAlert(
                user,
                NotificationType.PAY_BILL,
                "Pay Bill completed",
                "BDT " + request.amount() + " bill payment to " + request.billerCode() + " was completed.",
                Map.of("transactionReference", transactionReference, "type", TransactionType.PAY_BILL.name())
        );

        return new PayBillResponse(
                true,
                "Pay Bill completed successfully.",
                transaction.getTransactionReference(),
                transaction.getStatus(),
                transaction.getAmount(),
                balanceAfter,
                request.billerCode(),
                request.billAccountNumber(),
                transaction.getCreatedAt()
        );
    }

    private User currentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));
    }

    private void ensureActiveUser(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new IllegalArgumentException("Only active users can pay bills.");
        }
    }

    private void ensureActiveWallet(Wallet wallet) {
        if (wallet.getStatus() != WalletStatus.ACTIVE) {
            throw new IllegalArgumentException("User wallet is not active.");
        }
    }

    private void ensureSufficientBalance(Wallet wallet, BigDecimal amount) {
        if (wallet.getBalance().compareTo(amount) < 0) {
            throw new IllegalArgumentException("User wallet has insufficient balance.");
        }
    }

    private IdempotencyKey reserveOrValidateIdempotency(User user, PayBillRequest request) {
        String requestHash = requestHash(request);
        return idempotencyKeyService.findForUser(user.getId(), request.idempotencyKey())
                .map(existing -> validateExistingIdempotency(existing, requestHash))
                .orElseGet(() -> idempotencyKeyService.reserve(
                        user,
                        request.idempotencyKey(),
                        requestHash,
                        IdempotencyOperationType.PAY_BILL,
                        Instant.now().plus(IDEMPOTENCY_EXPIRY_HOURS, ChronoUnit.HOURS)
                ));
    }

    private IdempotencyKey validateExistingIdempotency(IdempotencyKey existing, String requestHash) {
        if (!existing.getRequestHash().equals(requestHash)) {
            throw new IllegalArgumentException("Idempotency key was already used for a different Pay Bill request.");
        }
        if (existing.getStatus() == IdempotencyStatus.PROCESSING) {
            throw new IllegalArgumentException("The same Pay Bill request is already processing.");
        }
        if (existing.getStatus() == IdempotencyStatus.FAILED) {
            throw new IllegalArgumentException("The previous Pay Bill attempt failed. Use a new idempotency key.");
        }
        return existing;
    }

    private PayBillResponse completedResponse(IdempotencyKey idempotencyKey, PayBillRequest request) {
        return new PayBillResponse(
                true,
                "Pay Bill request was already completed.",
                completedTransactionReference(idempotencyKey),
                TransactionStatus.SUCCESS,
                request.amount(),
                completedBalanceAfter(idempotencyKey),
                request.billerCode(),
                request.billAccountNumber(),
                null
        );
    }

    private PayBillResponse failedResponse(String message, PayBillRequest request) {
        return new PayBillResponse(false, message, null, TransactionStatus.FAILED, request.amount(), null, request.billerCode(), request.billAccountNumber(), null);
    }

    private String uniqueTransactionReference(String prefix) {
        String reference;
        do {
            reference = prefix + "-" + UUID.randomUUID().toString().replace("-", "").substring(0, 24).toUpperCase();
        } while (transactionRecordRepository.existsByTransactionReference(reference));
        return reference;
    }

    private String description(PayBillRequest request) {
        String base = "Pay Bill to " + request.billerCode() + " for " + request.billAccountNumber();
        if (request.note() == null || request.note().isBlank()) {
            return base;
        }
        return base + ". Note: " + request.note().trim();
    }

    private String requestHash(PayBillRequest request) {
        return sha256(
                request.billerCode().trim()
                        + ":" + request.billAccountNumber().trim()
                        + ":" + request.amount()
                        + ":" + nullToEmpty(request.note())
        );
    }

    private String sha256(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 algorithm is not available.", exception);
        }
    }

    private String completedTransactionReference(IdempotencyKey idempotencyKey) {
        String responseBody = idempotencyKey.getResponseBody();
        if (responseBody == null || !responseBody.startsWith("SUCCESS:")) {
            return null;
        }
        String[] parts = responseBody.split(":", 3);
        return parts.length >= 2 ? parts[1] : null;
    }

    private BigDecimal completedBalanceAfter(IdempotencyKey idempotencyKey) {
        String responseBody = idempotencyKey.getResponseBody();
        if (responseBody == null || !responseBody.startsWith("SUCCESS:")) {
            return null;
        }
        String[] parts = responseBody.split(":", 3);
        return parts.length == 3 ? new BigDecimal(parts[2]) : null;
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}
