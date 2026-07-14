package com.smartkash.recharge.service.impl;

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
import com.smartkash.recharge.dto.request.CreateMobileRechargeRequest;
import com.smartkash.recharge.dto.response.MobileRechargeResponse;
import com.smartkash.recharge.entity.MobileRecharge;
import com.smartkash.recharge.mapper.MobileRechargeMapper;
import com.smartkash.recharge.repository.MobileRechargeRepository;
import com.smartkash.recharge.service.MobileRechargeService;
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
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class MobileRechargeServiceImpl implements MobileRechargeService {

    private static final int IDEMPOTENCY_EXPIRY_HOURS = 24;

    private final UserRepository userRepository;
    private final MobileRechargeRepository mobileRechargeRepository;
    private final MobileRechargeMapper mobileRechargeMapper;
    private final WalletRepository walletRepository;
    private final TransactionRecordRepository transactionRecordRepository;
    private final LedgerEntryRepository ledgerEntryRepository;
    private final IdempotencyKeyService idempotencyKeyService;
    private final AuthService authService;
    private final TransactionAlertService transactionAlertService;

    public MobileRechargeServiceImpl(
            UserRepository userRepository,
            MobileRechargeRepository mobileRechargeRepository,
            MobileRechargeMapper mobileRechargeMapper,
            WalletRepository walletRepository,
            TransactionRecordRepository transactionRecordRepository,
            LedgerEntryRepository ledgerEntryRepository,
            IdempotencyKeyService idempotencyKeyService,
            AuthService authService,
            TransactionAlertService transactionAlertService
    ) {
        this.userRepository = userRepository;
        this.mobileRechargeRepository = mobileRechargeRepository;
        this.mobileRechargeMapper = mobileRechargeMapper;
        this.walletRepository = walletRepository;
        this.transactionRecordRepository = transactionRecordRepository;
        this.ledgerEntryRepository = ledgerEntryRepository;
        this.idempotencyKeyService = idempotencyKeyService;
        this.authService = authService;
        this.transactionAlertService = transactionAlertService;
    }

    @Override
    @Transactional
    public MobileRechargeResponse createRecharge(JwtPrincipal principal, CreateMobileRechargeRequest request) {
        User user = currentUser(principal);
        ensureActiveUser(user);

        PinVerificationResponse pinVerification = authService.verifyPin(principal, new VerifyPinRequest(request.pin()));
        if (!pinVerification.verified()) {
            throw new IllegalArgumentException("PIN verification failed.");
        }

        String requestHash = requestHash(request);
        IdempotencyKey idempotencyKey = reserveOrValidateIdempotency(user, request.idempotencyKey(), requestHash);
        if (idempotencyKey.getStatus() == IdempotencyStatus.COMPLETED) {
            return completedRechargeResponse(idempotencyKey);
        }

        Wallet wallet = walletRepository.findByUserIdForUpdate(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("User wallet was not found."));
        ensureActiveWallet(wallet);
        ensureSufficientBalance(wallet, request.amount());

        BigDecimal balanceAfter = wallet.debit(request.amount());
        String transactionReference = uniqueTransactionReference();

        TransactionRecord transaction = transactionRecordRepository.save(new TransactionRecord(
                transactionReference,
                user,
                TransactionType.MOBILE_RECHARGE,
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
                "Mobile Recharge wallet debit"
        ));

        MobileRecharge recharge = new MobileRecharge(
                user,
                request.operator(),
                request.mobileNumber(),
                request.amount()
        );
        recharge.attachTransactionReference(transaction.getTransactionReference());
        MobileRecharge savedRecharge = mobileRechargeRepository.save(recharge);
        idempotencyKeyService.markCompleted(
                idempotencyKey,
                "SUCCESS:" + savedRecharge.getId() + ":" + transactionReference + ":" + balanceAfter
        );
        transactionAlertService.sendTransactionAlert(
                user,
                NotificationType.RECHARGE,
                "Mobile Recharge completed",
                "BDT " + request.amount() + " recharge to " + request.mobileNumber() + " was completed.",
                Map.of("transactionReference", transactionReference, "rechargeId", String.valueOf(savedRecharge.getId()))
        );

        return mobileRechargeMapper.toResponse(savedRecharge, balanceAfter);
    }

    @Override
    @Transactional(readOnly = true)
    public List<MobileRechargeResponse> getCurrentUserRecharges(JwtPrincipal principal) {
        User user = currentUser(principal);
        return mobileRechargeRepository.findByUser_IdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(mobileRechargeMapper::toResponse)
                .toList();
    }

    private User currentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));
    }

    private void ensureActiveUser(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new IllegalArgumentException("Only active users can create mobile recharge records.");
        }
    }

    private IdempotencyKey reserveOrValidateIdempotency(User user, String key, String requestHash) {
        return idempotencyKeyService.findForUser(user.getId(), key)
                .map(existing -> validateExistingIdempotency(existing, requestHash))
                .orElseGet(() -> idempotencyKeyService.reserve(
                        user,
                        key,
                        requestHash,
                        IdempotencyOperationType.MOBILE_RECHARGE,
                        Instant.now().plus(IDEMPOTENCY_EXPIRY_HOURS, ChronoUnit.HOURS)
                ));
    }

    private IdempotencyKey validateExistingIdempotency(IdempotencyKey existing, String requestHash) {
        if (!existing.getRequestHash().equals(requestHash)) {
            throw new IllegalArgumentException("Idempotency key was already used for a different Mobile Recharge request.");
        }
        if (existing.getStatus() == IdempotencyStatus.PROCESSING) {
            throw new IllegalArgumentException("The same Mobile Recharge request is already processing.");
        }
        if (existing.getStatus() == IdempotencyStatus.FAILED) {
            throw new IllegalArgumentException("The previous Mobile Recharge attempt failed. Use a new idempotency key.");
        }
        return existing;
    }

    private MobileRechargeResponse completedRechargeResponse(IdempotencyKey idempotencyKey) {
        String transactionReference = completedTransactionReference(idempotencyKey);
        BigDecimal balanceAfter = completedBalanceAfter(idempotencyKey);
        return mobileRechargeRepository.findByTransactionReference(transactionReference)
                .map(recharge -> mobileRechargeMapper.toResponse(recharge, balanceAfter))
                .orElseThrow(() -> new ResourceNotFoundException("Completed Mobile Recharge record was not found."));
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

    private String uniqueTransactionReference() {
        String reference;
        do {
            reference = "RC-" + UUID.randomUUID().toString().replace("-", "").substring(0, 24).toUpperCase();
        } while (transactionRecordRepository.existsByTransactionReference(reference));
        return reference;
    }

    private String description(CreateMobileRechargeRequest request) {
        String base = "Mobile Recharge to " + request.mobileNumber() + " (" + request.operator() + ")";
        if (request.note() == null || request.note().isBlank()) {
            return base;
        }
        return base + ". Note: " + request.note().trim();
    }

    private String requestHash(CreateMobileRechargeRequest request) {
        return sha256(
                request.operator()
                        + ":" + request.mobileNumber().trim()
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
        String[] parts = responseBody.split(":", 4);
        return parts.length >= 3 ? parts[2] : null;
    }

    private BigDecimal completedBalanceAfter(IdempotencyKey idempotencyKey) {
        String responseBody = idempotencyKey.getResponseBody();
        if (responseBody == null || !responseBody.startsWith("SUCCESS:")) {
            return null;
        }
        String[] parts = responseBody.split(":", 4);
        if (parts.length < 4) {
            return null;
        }
        return new BigDecimal(parts[3]);
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}
