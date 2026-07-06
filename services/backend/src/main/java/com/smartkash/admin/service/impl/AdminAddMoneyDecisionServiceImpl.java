package com.smartkash.admin.service.impl;

import com.smartkash.addmoney.dto.response.AddMoneyRequestResponse;
import com.smartkash.addmoney.entity.AddMoneyRequest;
import com.smartkash.addmoney.enums.AddMoneyStatus;
import com.smartkash.addmoney.mapper.AddMoneyRequestMapper;
import com.smartkash.addmoney.repository.AddMoneyRequestRepository;
import com.smartkash.admin.dto.request.AdminAddMoneyDecisionRequest;
import com.smartkash.admin.dto.response.AdminAddMoneyDecisionResponse;
import com.smartkash.admin.service.AdminAddMoneyDecisionService;
import com.smartkash.audit.enums.AuditAction;
import com.smartkash.audit.enums.AuditTargetType;
import com.smartkash.audit.service.AdminAuditLogService;
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
public class AdminAddMoneyDecisionServiceImpl implements AdminAddMoneyDecisionService {

    private static final int IDEMPOTENCY_EXPIRY_HOURS = 24;

    private final UserRepository userRepository;
    private final AddMoneyRequestRepository addMoneyRequestRepository;
    private final AddMoneyRequestMapper addMoneyRequestMapper;
    private final WalletRepository walletRepository;
    private final TransactionRecordRepository transactionRecordRepository;
    private final LedgerEntryRepository ledgerEntryRepository;
    private final IdempotencyKeyService idempotencyKeyService;
    private final AdminAuditLogService adminAuditLogService;
    private final TransactionAlertService transactionAlertService;

    public AdminAddMoneyDecisionServiceImpl(
            UserRepository userRepository,
            AddMoneyRequestRepository addMoneyRequestRepository,
            AddMoneyRequestMapper addMoneyRequestMapper,
            WalletRepository walletRepository,
            TransactionRecordRepository transactionRecordRepository,
            LedgerEntryRepository ledgerEntryRepository,
            IdempotencyKeyService idempotencyKeyService,
            AdminAuditLogService adminAuditLogService,
            TransactionAlertService transactionAlertService
    ) {
        this.userRepository = userRepository;
        this.addMoneyRequestRepository = addMoneyRequestRepository;
        this.addMoneyRequestMapper = addMoneyRequestMapper;
        this.walletRepository = walletRepository;
        this.transactionRecordRepository = transactionRecordRepository;
        this.ledgerEntryRepository = ledgerEntryRepository;
        this.idempotencyKeyService = idempotencyKeyService;
        this.adminAuditLogService = adminAuditLogService;
        this.transactionAlertService = transactionAlertService;
    }

    @Override
    @Transactional
    public AdminAddMoneyDecisionResponse approve(
            JwtPrincipal principal,
            Long requestId,
            AdminAddMoneyDecisionRequest request
    ) {
        User adminUser = currentAdmin(principal);
        String requestHash = requestHash("APPROVE", requestId, request.note());
        IdempotencyKey idempotencyKey = reserveOrValidateIdempotency(adminUser, request.idempotencyKey(), requestHash);

        AddMoneyRequest addMoneyRequest = addMoneyRequestRepository.findByIdForUpdate(requestId)
                .orElseThrow(() -> new ResourceNotFoundException("Add Money request was not found."));

        if (idempotencyKey.getStatus() == IdempotencyStatus.COMPLETED) {
            return response(
                    addMoneyRequest,
                    completedTransactionReference(idempotencyKey),
                    currentWalletBalance(addMoneyRequest.getUser().getId())
            );
        }

        ensurePending(addMoneyRequest);

        Wallet wallet = walletRepository.findByUserIdForUpdate(addMoneyRequest.getUser().getId())
                .orElseThrow(() -> new ResourceNotFoundException("Customer wallet was not found."));
        ensureActiveWallet(wallet);

        BigDecimal balanceAfter = wallet.credit(addMoneyRequest.getAmount());
        String transactionReference = uniqueTransactionReference();
        TransactionRecord transaction = new TransactionRecord(
                transactionReference,
                addMoneyRequest.getUser(),
                TransactionType.ADD_MONEY,
                TransactionStatus.SUCCESS,
                addMoneyRequest.getAmount(),
                null,
                "Add Money request approved by admin"
        );
        transactionRecordRepository.save(transaction);
        ledgerEntryRepository.save(new LedgerEntry(
                wallet,
                addMoneyRequest.getUser(),
                transactionReference,
                null,
                LedgerEntryType.CREDIT,
                addMoneyRequest.getAmount(),
                balanceAfter,
                "Add Money wallet credit"
        ));

        addMoneyRequest.approve(adminUser);
        AddMoneyRequest savedRequest = addMoneyRequestRepository.save(addMoneyRequest);
        adminAuditLogService.recordAdminAction(
                adminUser,
                AuditAction.ADD_MONEY_APPROVE,
                AuditTargetType.ADD_MONEY_REQUEST,
                String.valueOf(savedRequest.getId()),
                "Approved Add Money request. transactionReference=" + transactionReference
        );
        idempotencyKeyService.markCompleted(idempotencyKey, "APPROVED:" + savedRequest.getId() + ":" + transactionReference);
        transactionAlertService.sendTransactionAlert(
                savedRequest.getUser(),
                NotificationType.ADD_MONEY,
                "Add Money approved",
                "Your Add Money request of BDT " + savedRequest.getAmount() + " was approved.",
                Map.of("transactionReference", transactionReference, "type", TransactionType.ADD_MONEY.name())
        );

        return response(savedRequest, transactionReference, balanceAfter);
    }

    @Override
    @Transactional
    public AdminAddMoneyDecisionResponse reject(
            JwtPrincipal principal,
            Long requestId,
            AdminAddMoneyDecisionRequest request
    ) {
        User adminUser = currentAdmin(principal);
        String requestHash = requestHash("REJECT", requestId, request.note());
        IdempotencyKey idempotencyKey = reserveOrValidateIdempotency(adminUser, request.idempotencyKey(), requestHash);

        AddMoneyRequest addMoneyRequest = addMoneyRequestRepository.findByIdForUpdate(requestId)
                .orElseThrow(() -> new ResourceNotFoundException("Add Money request was not found."));

        if (idempotencyKey.getStatus() == IdempotencyStatus.COMPLETED) {
            return response(addMoneyRequest, null, currentWalletBalance(addMoneyRequest.getUser().getId()));
        }

        ensurePending(addMoneyRequest);
        addMoneyRequest.reject(adminUser);
        AddMoneyRequest savedRequest = addMoneyRequestRepository.save(addMoneyRequest);
        adminAuditLogService.recordAdminAction(
                adminUser,
                AuditAction.ADD_MONEY_REJECT,
                AuditTargetType.ADD_MONEY_REQUEST,
                String.valueOf(savedRequest.getId()),
                "Rejected Add Money request. note=" + nullToEmpty(request.note())
        );
        idempotencyKeyService.markCompleted(idempotencyKey, "REJECTED:" + savedRequest.getId());
        transactionAlertService.sendTransactionAlert(
                savedRequest.getUser(),
                NotificationType.ADD_MONEY,
                "Add Money rejected",
                "Your Add Money request of BDT " + savedRequest.getAmount() + " was rejected.",
                Map.of("requestId", String.valueOf(savedRequest.getId()), "status", AddMoneyStatus.REJECTED.name())
        );

        return response(savedRequest, null, currentWalletBalance(savedRequest.getUser().getId()));
    }

    private User currentAdmin(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("Admin user account was not found."));
    }

    private IdempotencyKey reserveOrValidateIdempotency(User adminUser, String key, String requestHash) {
        return idempotencyKeyService.findForUser(adminUser.getId(), key)
                .map(existing -> validateExistingIdempotency(existing, requestHash))
                .orElseGet(() -> idempotencyKeyService.reserve(
                        adminUser,
                        key,
                        requestHash,
                        IdempotencyOperationType.ADD_MONEY,
                        Instant.now().plus(IDEMPOTENCY_EXPIRY_HOURS, ChronoUnit.HOURS)
                ));
    }

    private IdempotencyKey validateExistingIdempotency(IdempotencyKey existing, String requestHash) {
        if (!existing.getRequestHash().equals(requestHash)) {
            throw new IllegalArgumentException("Idempotency key was already used for a different Add Money decision.");
        }
        if (existing.getStatus() == IdempotencyStatus.PROCESSING) {
            throw new IllegalArgumentException("The same Add Money decision is already processing.");
        }
        if (existing.getStatus() == IdempotencyStatus.FAILED) {
            throw new IllegalArgumentException("The previous Add Money decision attempt failed. Use a new idempotency key.");
        }
        return existing;
    }

    private void ensurePending(AddMoneyRequest request) {
        if (request.getStatus() != AddMoneyStatus.PENDING) {
            throw new IllegalArgumentException("Only pending Add Money requests can be approved or rejected.");
        }
    }

    private void ensureActiveWallet(Wallet wallet) {
        if (wallet.getStatus() != WalletStatus.ACTIVE) {
            throw new IllegalArgumentException("Customer wallet is not active.");
        }
    }

    private BigDecimal currentWalletBalance(Long userId) {
        return walletRepository.findByUserId(userId)
                .map(Wallet::getBalance)
                .orElse(null);
    }

    private AdminAddMoneyDecisionResponse response(
            AddMoneyRequest request,
            String transactionReference,
            BigDecimal walletBalanceAfter
    ) {
        AddMoneyRequestResponse requestResponse = addMoneyRequestMapper.toResponse(request);
        return new AdminAddMoneyDecisionResponse(requestResponse, transactionReference, walletBalanceAfter);
    }

    private String uniqueTransactionReference() {
        String reference;
        do {
            reference = "AM-" + UUID.randomUUID().toString().replace("-", "").substring(0, 24).toUpperCase();
        } while (transactionRecordRepository.existsByTransactionReference(reference));
        return reference;
    }

    private String completedTransactionReference(IdempotencyKey idempotencyKey) {
        String responseBody = idempotencyKey.getResponseBody();
        if (responseBody == null || !responseBody.startsWith("APPROVED:")) {
            return null;
        }
        String[] parts = responseBody.split(":", 3);
        return parts.length == 3 ? parts[2] : null;
    }

    private String requestHash(String action, Long requestId, String note) {
        return sha256(action + ":" + requestId + ":" + nullToEmpty(note));
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
