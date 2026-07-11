package com.smartkash.cashout.service.impl;

import com.smartkash.auth.dto.request.VerifyPinRequest;
import com.smartkash.auth.dto.response.PinVerificationResponse;
import com.smartkash.auth.service.AuthService;
import com.smartkash.cashout.dto.request.CashOutRequest;
import com.smartkash.cashout.dto.response.CashOutResponse;
import com.smartkash.cashout.service.CashOutService;
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
public class CashOutServiceImpl implements CashOutService {

    private static final int IDEMPOTENCY_EXPIRY_HOURS = 24;

    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final TransactionRecordRepository transactionRecordRepository;
    private final LedgerEntryRepository ledgerEntryRepository;
    private final IdempotencyKeyService idempotencyKeyService;
    private final AuthService authService;
    private final TransactionAlertService transactionAlertService;

    public CashOutServiceImpl(
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
    public CashOutResponse cashOut(JwtPrincipal principal, CashOutRequest request) {
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
        String transactionReference = uniqueTransactionReference("CO");
        TransactionRecord transaction = transactionRecordRepository.save(new TransactionRecord(
                transactionReference,
                user,
                TransactionType.CASH_OUT,
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
                "Cash Out wallet debit"
        ));

        idempotencyKeyService.markCompleted(idempotencyKey, "SUCCESS:" + transactionReference + ":" + balanceAfter);
        transactionAlertService.sendTransactionAlert(
                user,
                NotificationType.CASH_OUT,
                "Cash Out completed",
                "BDT " + request.amount() + " cash out through agent " + request.agentNumber() + " was completed.",
                Map.of("transactionReference", transactionReference, "type", TransactionType.CASH_OUT.name())
        );

        return new CashOutResponse(
                true,
                "Cash Out completed successfully.",
                transaction.getTransactionReference(),
                transaction.getStatus(),
                transaction.getAmount(),
                balanceAfter,
                request.agentNumber(),
                transaction.getCreatedAt()
        );
    }

    private User currentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));
    }

    private void ensureActiveUser(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new IllegalArgumentException("Only active users can cash out.");
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

    private IdempotencyKey reserveOrValidateIdempotency(User user, CashOutRequest request) {
        String requestHash = requestHash(request);
        return idempotencyKeyService.findForUser(user.getId(), request.idempotencyKey())
                .map(existing -> validateExistingIdempotency(existing, requestHash))
                .orElseGet(() -> idempotencyKeyService.reserve(
                        user,
                        request.idempotencyKey(),
                        requestHash,
                        IdempotencyOperationType.CASH_OUT,
                        Instant.now().plus(IDEMPOTENCY_EXPIRY_HOURS, ChronoUnit.HOURS)
                ));
    }

    private IdempotencyKey validateExistingIdempotency(IdempotencyKey existing, String requestHash) {
        if (!existing.getRequestHash().equals(requestHash)) {
            throw new IllegalArgumentException("Idempotency key was already used for a different Cash Out request.");
        }
        if (existing.getStatus() == IdempotencyStatus.PROCESSING) {
            throw new IllegalArgumentException("The same Cash Out request is already processing.");
        }
        if (existing.getStatus() == IdempotencyStatus.FAILED) {
            throw new IllegalArgumentException("The previous Cash Out attempt failed. Use a new idempotency key.");
        }
        return existing;
    }

    private CashOutResponse completedResponse(IdempotencyKey idempotencyKey, CashOutRequest request) {
        return new CashOutResponse(
                true,
                "Cash Out request was already completed.",
                completedTransactionReference(idempotencyKey),
                TransactionStatus.SUCCESS,
                request.amount(),
                completedBalanceAfter(idempotencyKey),
                request.agentNumber(),
                null
        );
    }

    private CashOutResponse failedResponse(String message, CashOutRequest request) {
        return new CashOutResponse(false, message, null, TransactionStatus.FAILED, request.amount(), null, request.agentNumber(), null);
    }

    private String uniqueTransactionReference(String prefix) {
        String reference;
        do {
            reference = prefix + "-" + UUID.randomUUID().toString().replace("-", "").substring(0, 24).toUpperCase();
        } while (transactionRecordRepository.existsByTransactionReference(reference));
        return reference;
    }

    private String description(CashOutRequest request) {
        String base = "Cash Out through agent " + request.agentNumber();
        if (request.note() == null || request.note().isBlank()) {
            return base;
        }
        return base + ". Note: " + request.note().trim();
    }

    private String requestHash(CashOutRequest request) {
        return sha256(request.agentNumber().trim() + ":" + request.amount() + ":" + nullToEmpty(request.note()));
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
