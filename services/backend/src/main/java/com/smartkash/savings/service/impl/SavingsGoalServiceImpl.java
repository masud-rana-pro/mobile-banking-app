package com.smartkash.savings.service.impl;

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
import com.smartkash.savings.dto.request.CreateSavingsGoalRequest;
import com.smartkash.savings.dto.request.SavingsDepositRequest;
import com.smartkash.savings.dto.response.SavingsDepositResponse;
import com.smartkash.savings.dto.response.SavingsGoalResponse;
import com.smartkash.savings.entity.SavingsGoal;
import com.smartkash.savings.enums.SavingsGoalStatus;
import com.smartkash.savings.mapper.SavingsGoalMapper;
import com.smartkash.savings.repository.SavingsGoalRepository;
import com.smartkash.savings.service.SavingsGoalService;
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
import java.util.UUID;

@Service
public class SavingsGoalServiceImpl implements SavingsGoalService {

    private static final int IDEMPOTENCY_EXPIRY_HOURS = 24;

    private final UserRepository userRepository;
    private final SavingsGoalRepository savingsGoalRepository;
    private final SavingsGoalMapper savingsGoalMapper;
    private final WalletRepository walletRepository;
    private final TransactionRecordRepository transactionRecordRepository;
    private final LedgerEntryRepository ledgerEntryRepository;
    private final IdempotencyKeyService idempotencyKeyService;
    private final AuthService authService;

    public SavingsGoalServiceImpl(
            UserRepository userRepository,
            SavingsGoalRepository savingsGoalRepository,
            SavingsGoalMapper savingsGoalMapper,
            WalletRepository walletRepository,
            TransactionRecordRepository transactionRecordRepository,
            LedgerEntryRepository ledgerEntryRepository,
            IdempotencyKeyService idempotencyKeyService,
            AuthService authService
    ) {
        this.userRepository = userRepository;
        this.savingsGoalRepository = savingsGoalRepository;
        this.savingsGoalMapper = savingsGoalMapper;
        this.walletRepository = walletRepository;
        this.transactionRecordRepository = transactionRecordRepository;
        this.ledgerEntryRepository = ledgerEntryRepository;
        this.idempotencyKeyService = idempotencyKeyService;
        this.authService = authService;
    }

    @Override
    @Transactional
    public SavingsGoalResponse createCurrentUserGoal(JwtPrincipal principal, CreateSavingsGoalRequest request) {
        User user = currentUser(principal);
        ensureActiveUser(user);
        SavingsGoal goal = new SavingsGoal(
                user,
                request.name(),
                request.targetAmount(),
                request.targetDate()
        );
        return savingsGoalMapper.toResponse(savingsGoalRepository.save(goal));
    }

    @Override
    @Transactional(readOnly = true)
    public List<SavingsGoalResponse> getCurrentUserGoals(JwtPrincipal principal) {
        User user = currentUser(principal);
        return savingsGoalRepository.findByUser_IdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(savingsGoalMapper::toResponse)
                .toList();
    }

    @Override
    @Transactional
    public SavingsDepositResponse depositToGoal(JwtPrincipal principal, Long goalId, SavingsDepositRequest request) {
        User user = currentUser(principal);
        ensureActiveUser(user);

        SavingsGoal goal = savingsGoalRepository.findByIdAndUserIdForUpdate(goalId, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Savings goal was not found."));
        ensureActiveGoal(goal);

        PinVerificationResponse pinVerification = authService.verifyPin(principal, new VerifyPinRequest(request.pin()));
        if (!pinVerification.verified()) {
            return failedResponse("PIN verification failed.", request.amount(), goal);
        }

        String requestHash = requestHash(goalId, request);
        IdempotencyKey idempotencyKey = reserveOrValidateIdempotency(user, request.idempotencyKey(), requestHash);
        if (idempotencyKey.getStatus() == IdempotencyStatus.COMPLETED) {
            return completedResponse(idempotencyKey, request.amount(), goal);
        }

        Wallet wallet = walletRepository.findByUserIdForUpdate(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("User wallet was not found."));
        ensureActiveWallet(wallet);
        ensureSufficientBalance(wallet, request.amount());

        BigDecimal walletBalanceAfter = wallet.debit(request.amount());
        goal.deposit(request.amount());
        SavingsGoal savedGoal = savingsGoalRepository.save(goal);

        String transactionReference = uniqueTransactionReference();
        TransactionRecord transaction = transactionRecordRepository.save(new TransactionRecord(
                transactionReference,
                user,
                TransactionType.SAVINGS_DEPOSIT,
                TransactionStatus.SUCCESS,
                request.amount(),
                null,
                description(request.note(), savedGoal)
        ));
        ledgerEntryRepository.save(new LedgerEntry(
                wallet,
                user,
                transactionReference,
                null,
                LedgerEntryType.DEBIT,
                request.amount(),
                walletBalanceAfter,
                "Savings deposit wallet debit"
        ));

        idempotencyKeyService.markCompleted(
                idempotencyKey,
                "SUCCESS:" + transactionReference + ":" + walletBalanceAfter
        );

        return new SavingsDepositResponse(
                true,
                "Savings deposit completed successfully.",
                transaction.getTransactionReference(),
                transaction.getStatus(),
                transaction.getAmount(),
                walletBalanceAfter,
                savingsGoalMapper.toResponse(savedGoal),
                transaction.getCreatedAt()
        );
    }

    private User currentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));
    }

    private void ensureActiveUser(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new IllegalArgumentException("Only active users can create savings goals.");
        }
    }

    private IdempotencyKey reserveOrValidateIdempotency(User user, String key, String requestHash) {
        return idempotencyKeyService.findForUser(user.getId(), key)
                .map(existing -> validateExistingIdempotency(existing, requestHash))
                .orElseGet(() -> idempotencyKeyService.reserve(
                        user,
                        key,
                        requestHash,
                        IdempotencyOperationType.SAVINGS_DEPOSIT,
                        Instant.now().plus(IDEMPOTENCY_EXPIRY_HOURS, ChronoUnit.HOURS)
                ));
    }

    private IdempotencyKey validateExistingIdempotency(IdempotencyKey existing, String requestHash) {
        if (!existing.getRequestHash().equals(requestHash)) {
            throw new IllegalArgumentException("Idempotency key was already used for a different Savings Deposit request.");
        }
        if (existing.getStatus() == IdempotencyStatus.PROCESSING) {
            throw new IllegalArgumentException("The same Savings Deposit request is already processing.");
        }
        if (existing.getStatus() == IdempotencyStatus.FAILED) {
            throw new IllegalArgumentException("The previous Savings Deposit attempt failed. Use a new idempotency key.");
        }
        return existing;
    }

    private void ensureActiveGoal(SavingsGoal goal) {
        if (goal.getStatus() != SavingsGoalStatus.ACTIVE) {
            throw new IllegalArgumentException("Only active savings goals can receive deposits.");
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

    private SavingsDepositResponse completedResponse(
            IdempotencyKey idempotencyKey,
            BigDecimal amount,
            SavingsGoal goal
    ) {
        return new SavingsDepositResponse(
                true,
                "Savings Deposit request was already completed.",
                completedTransactionReference(idempotencyKey),
                TransactionStatus.SUCCESS,
                amount,
                completedWalletBalanceAfter(idempotencyKey),
                savingsGoalMapper.toResponse(goal),
                null
        );
    }

    private SavingsDepositResponse failedResponse(String message, BigDecimal amount, SavingsGoal goal) {
        return new SavingsDepositResponse(
                false,
                message,
                null,
                TransactionStatus.FAILED,
                amount,
                null,
                savingsGoalMapper.toResponse(goal),
                null
        );
    }

    private String uniqueTransactionReference() {
        String reference;
        do {
            reference = "SD-" + UUID.randomUUID().toString().replace("-", "").substring(0, 24).toUpperCase();
        } while (transactionRecordRepository.existsByTransactionReference(reference));
        return reference;
    }

    private String description(String note, SavingsGoal goal) {
        String base = "Savings Deposit to goal " + goal.getName();
        if (note == null || note.isBlank()) {
            return base;
        }
        return base + ". Note: " + note.trim();
    }

    private String requestHash(Long goalId, SavingsDepositRequest request) {
        return sha256(goalId + ":" + request.amount() + ":" + nullToEmpty(request.note()));
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

    private BigDecimal completedWalletBalanceAfter(IdempotencyKey idempotencyKey) {
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
