package com.smartkash.addmoney.service.impl;

import com.smartkash.addmoney.dto.request.CreateAddMoneyRequest;
import com.smartkash.addmoney.dto.response.AddMoneyRequestResponse;
import com.smartkash.addmoney.entity.AddMoneyRequest;
import com.smartkash.addmoney.enums.AddMoneySourceType;
import com.smartkash.addmoney.mapper.AddMoneyRequestMapper;
import com.smartkash.addmoney.repository.AddMoneyRequestRepository;
import com.smartkash.addmoney.service.AddMoneyRequestService;
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
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class AddMoneyRequestServiceImpl implements AddMoneyRequestService {

    private static final int IDEMPOTENCY_EXPIRY_HOURS = 24;

    private final UserRepository userRepository;
    private final AddMoneyRequestRepository addMoneyRequestRepository;
    private final AddMoneyRequestMapper addMoneyRequestMapper;
    private final WalletRepository walletRepository;
    private final TransactionRecordRepository transactionRecordRepository;
    private final LedgerEntryRepository ledgerEntryRepository;
    private final IdempotencyKeyService idempotencyKeyService;
    private final TransactionAlertService transactionAlertService;

    public AddMoneyRequestServiceImpl(
            UserRepository userRepository,
            AddMoneyRequestRepository addMoneyRequestRepository,
            AddMoneyRequestMapper addMoneyRequestMapper,
            WalletRepository walletRepository,
            TransactionRecordRepository transactionRecordRepository,
            LedgerEntryRepository ledgerEntryRepository,
            IdempotencyKeyService idempotencyKeyService,
            TransactionAlertService transactionAlertService
    ) {
        this.userRepository = userRepository;
        this.addMoneyRequestRepository = addMoneyRequestRepository;
        this.addMoneyRequestMapper = addMoneyRequestMapper;
        this.walletRepository = walletRepository;
        this.transactionRecordRepository = transactionRecordRepository;
        this.ledgerEntryRepository = ledgerEntryRepository;
        this.idempotencyKeyService = idempotencyKeyService;
        this.transactionAlertService = transactionAlertService;
    }

    @Override
    @Transactional
    public AddMoneyRequestResponse createCurrentUserRequest(
            JwtPrincipal principal,
            CreateAddMoneyRequest request
    ) {
        User user = currentUser(principal);
        ensureActiveUser(user);

        String requestHash = requestHash(request.amount(), request.sourceType().name(), request.note());
        IdempotencyKey idempotencyKey = reserveOrValidateIdempotency(user, request.idempotencyKey(), requestHash);
        if (idempotencyKey.getStatus() == IdempotencyStatus.COMPLETED) {
            return completedAddMoneyResponse(idempotencyKey);
        }

        Wallet wallet = walletRepository.findByUserIdForUpdate(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Customer wallet was not found."));
        ensureActiveWallet(wallet);

        AddMoneyRequest addMoneyRequest = new AddMoneyRequest(
                user,
                request.amount(),
                request.sourceType(),
                request.note()
        );
        addMoneyRequest.completeInstantly();
        AddMoneyRequest savedRequest = addMoneyRequestRepository.save(addMoneyRequest);

        BigDecimal balanceAfter = wallet.credit(request.amount());
        String transactionReference = uniqueTransactionReference();
        TransactionRecord transaction = new TransactionRecord(
                transactionReference,
                user,
                TransactionType.ADD_MONEY,
                TransactionStatus.SUCCESS,
                request.amount(),
                null,
                "Instant Add Money from " + sourceTypeLabel(request.sourceType())
        );
        transactionRecordRepository.save(transaction);
        ledgerEntryRepository.save(new LedgerEntry(
                wallet,
                user,
                transactionReference,
                null,
                LedgerEntryType.CREDIT,
                request.amount(),
                balanceAfter,
                "Instant Add Money wallet credit"
        ));

        idempotencyKeyService.markCompleted(
                idempotencyKey,
                "ADD_MONEY:" + savedRequest.getId() + ":" + transactionReference + ":" + balanceAfter
        );
        transactionAlertService.sendTransactionAlert(
                user,
                NotificationType.ADD_MONEY,
                "Add Money successful",
                "BDT " + savedRequest.getAmount() + " was added to your SmartKash wallet.",
                Map.of("transactionReference", transactionReference, "type", TransactionType.ADD_MONEY.name())
        );

        return addMoneyRequestMapper.toResponse(savedRequest, transactionReference, balanceAfter);
    }

    @Override
    @Transactional(readOnly = true)
    public List<AddMoneyRequestResponse> getCurrentUserRequests(JwtPrincipal principal) {
        User user = currentUser(principal);
        return addMoneyRequestRepository.findByUser_IdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(addMoneyRequestMapper::toResponse)
                .toList();
    }

    private User currentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));
    }

    private void ensureActiveUser(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new IllegalArgumentException("Only active users can add money.");
        }
    }

    private void ensureActiveWallet(Wallet wallet) {
        if (wallet.getStatus() != WalletStatus.ACTIVE) {
            throw new IllegalArgumentException("Customer wallet is not active.");
        }
    }

    private IdempotencyKey reserveOrValidateIdempotency(User user, String key, String requestHash) {
        return idempotencyKeyService.findForUser(user.getId(), key)
                .map(existing -> validateExistingIdempotency(existing, requestHash))
                .orElseGet(() -> idempotencyKeyService.reserve(
                        user,
                        key,
                        requestHash,
                        IdempotencyOperationType.ADD_MONEY,
                        Instant.now().plus(IDEMPOTENCY_EXPIRY_HOURS, ChronoUnit.HOURS)
                ));
    }

    private IdempotencyKey validateExistingIdempotency(IdempotencyKey existing, String requestHash) {
        if (!existing.getRequestHash().equals(requestHash)) {
            throw new IllegalArgumentException("Idempotency key was already used for a different Add Money request.");
        }
        if (existing.getStatus() == IdempotencyStatus.PROCESSING) {
            throw new IllegalArgumentException("The same Add Money request is already processing.");
        }
        if (existing.getStatus() == IdempotencyStatus.FAILED) {
            throw new IllegalArgumentException("The previous Add Money request failed. Use a new idempotency key.");
        }
        return existing;
    }

    private AddMoneyRequestResponse completedAddMoneyResponse(IdempotencyKey idempotencyKey) {
        String responseBody = idempotencyKey.getResponseBody();
        if (responseBody == null || !responseBody.startsWith("ADD_MONEY:")) {
            throw new IllegalArgumentException("Stored Add Money idempotency response is invalid.");
        }
        String[] parts = responseBody.split(":", 4);
        Long requestId = Long.parseLong(parts[1]);
        String transactionReference = parts.length >= 3 ? parts[2] : null;
        BigDecimal balanceAfter = parts.length >= 4 ? new BigDecimal(parts[3]) : null;
        AddMoneyRequest addMoneyRequest = addMoneyRequestRepository.findById(requestId)
                .orElseThrow(() -> new ResourceNotFoundException("Completed Add Money record was not found."));
        return addMoneyRequestMapper.toResponse(addMoneyRequest, transactionReference, balanceAfter);
    }

    private String uniqueTransactionReference() {
        String reference;
        do {
            reference = "AM-" + UUID.randomUUID().toString().replace("-", "").substring(0, 24).toUpperCase();
        } while (transactionRecordRepository.existsByTransactionReference(reference));
        return reference;
    }

    private String requestHash(BigDecimal amount, String sourceType, String note) {
        return sha256(amount.toPlainString() + ":" + sourceType + ":" + nullToEmpty(note));
    }

    private String sourceTypeLabel(AddMoneySourceType sourceType) {
        return switch (sourceType) {
            case DEMO_BANK -> "Bank Transfer";
            case DEMO_CARD -> "Card";
            case MANUAL -> "Manual Deposit";
        };
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

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}
