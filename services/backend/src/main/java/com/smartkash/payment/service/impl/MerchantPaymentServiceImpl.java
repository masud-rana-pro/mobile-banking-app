package com.smartkash.payment.service.impl;

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
import com.smartkash.merchant.entity.Merchant;
import com.smartkash.merchant.enums.MerchantStatus;
import com.smartkash.merchant.repository.MerchantRepository;
import com.smartkash.notification.enums.NotificationType;
import com.smartkash.notification.service.TransactionAlertService;
import com.smartkash.payment.dto.request.MerchantPaymentRequest;
import com.smartkash.payment.dto.response.MerchantPaymentResponse;
import com.smartkash.payment.service.MerchantPaymentService;
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
public class MerchantPaymentServiceImpl implements MerchantPaymentService {

    private static final int IDEMPOTENCY_EXPIRY_HOURS = 24;

    private final UserRepository userRepository;
    private final MerchantRepository merchantRepository;
    private final WalletRepository walletRepository;
    private final TransactionRecordRepository transactionRecordRepository;
    private final LedgerEntryRepository ledgerEntryRepository;
    private final IdempotencyKeyService idempotencyKeyService;
    private final AuthService authService;
    private final TransactionAlertService transactionAlertService;

    public MerchantPaymentServiceImpl(
            UserRepository userRepository,
            MerchantRepository merchantRepository,
            WalletRepository walletRepository,
            TransactionRecordRepository transactionRecordRepository,
            LedgerEntryRepository ledgerEntryRepository,
            IdempotencyKeyService idempotencyKeyService,
            AuthService authService,
            TransactionAlertService transactionAlertService
    ) {
        this.userRepository = userRepository;
        this.merchantRepository = merchantRepository;
        this.walletRepository = walletRepository;
        this.transactionRecordRepository = transactionRecordRepository;
        this.ledgerEntryRepository = ledgerEntryRepository;
        this.idempotencyKeyService = idempotencyKeyService;
        this.authService = authService;
        this.transactionAlertService = transactionAlertService;
    }

    @Override
    @Transactional
    public MerchantPaymentResponse payMerchant(JwtPrincipal principal, MerchantPaymentRequest request) {
        User customer = currentUser(principal);
        ensureActiveUser(customer, "Only active users can make merchant payments.");

        Merchant merchant = merchantRepository.findByMerchantNumber(request.merchantNumber().trim())
                .orElseThrow(() -> new ResourceNotFoundException("Merchant account was not found."));
        ensureActiveMerchant(merchant);

        User merchantUser = merchant.getUser();
        ensureActiveUser(merchantUser, "Merchant user account is not active.");
        ensureNotPayingOwnMerchant(customer, merchantUser);

        PinVerificationResponse pinVerification = authService.verifyPin(principal, new VerifyPinRequest(request.pin()));
        if (!pinVerification.verified()) {
            return failedResponse("PIN verification failed.", request.amount(), merchant);
        }

        String requestHash = requestHash(request);
        IdempotencyKey idempotencyKey = reserveOrValidateIdempotency(customer, request.idempotencyKey(), requestHash);
        if (idempotencyKey.getStatus() == IdempotencyStatus.COMPLETED) {
            return completedResponse(idempotencyKey, request.amount(), merchant);
        }

        Wallet customerWallet = walletRepository.findByUserIdForUpdate(customer.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Customer wallet was not found."));
        Wallet merchantWallet = walletRepository.findByUserIdForUpdate(merchantUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Merchant wallet was not found."));

        ensureActiveWallet(customerWallet, "Customer wallet is not active.");
        ensureActiveWallet(merchantWallet, "Merchant wallet is not active.");
        ensureSufficientBalance(customerWallet, request.amount());

        BigDecimal customerBalanceAfter = customerWallet.debit(request.amount());
        BigDecimal merchantBalanceAfter = merchantWallet.credit(request.amount());
        String customerTransactionReference = uniqueTransactionReference("MP");
        String merchantTransactionReference = uniqueTransactionReference("MR");
        String description = description(request.note(), merchant);

        TransactionRecord customerTransaction = transactionRecordRepository.save(new TransactionRecord(
                customerTransactionReference,
                customer,
                TransactionType.MERCHANT_PAYMENT,
                TransactionStatus.SUCCESS,
                request.amount(),
                merchantUser,
                description
        ));
        transactionRecordRepository.save(new TransactionRecord(
                merchantTransactionReference,
                merchantUser,
                TransactionType.MERCHANT_PAYMENT,
                TransactionStatus.SUCCESS,
                request.amount(),
                customer,
                "Merchant received payment from " + customer.getMobileNumber()
        ));

        LedgerEntry debitEntry = ledgerEntryRepository.save(new LedgerEntry(
                customerWallet,
                customer,
                customerTransactionReference,
                null,
                LedgerEntryType.DEBIT,
                request.amount(),
                customerBalanceAfter,
                "Merchant Payment wallet debit"
        ));
        LedgerEntry creditEntry = ledgerEntryRepository.save(new LedgerEntry(
                merchantWallet,
                merchantUser,
                customerTransactionReference,
                debitEntry,
                LedgerEntryType.CREDIT,
                request.amount(),
                merchantBalanceAfter,
                "Merchant Payment wallet credit"
        ));
        debitEntry.linkTo(creditEntry);
        ledgerEntryRepository.save(debitEntry);

        idempotencyKeyService.markCompleted(
                idempotencyKey,
                "SUCCESS:" + customerTransactionReference + ":" + customerBalanceAfter
        );
        transactionAlertService.sendTransactionAlert(
                customer,
                NotificationType.PAYMENT,
                "Merchant Payment completed",
                "You paid BDT " + request.amount() + " to " + merchant.getBusinessName() + ".",
                Map.of("transactionReference", customerTransactionReference, "type", TransactionType.MERCHANT_PAYMENT.name())
        );
        transactionAlertService.sendTransactionAlert(
                merchantUser,
                NotificationType.PAYMENT,
                "Merchant Payment received",
                "You received BDT " + request.amount() + " from " + customer.getMobileNumber() + ".",
                Map.of("transactionReference", customerTransactionReference, "type", TransactionType.MERCHANT_PAYMENT.name())
        );

        return new MerchantPaymentResponse(
                true,
                "Merchant Payment completed successfully.",
                customerTransaction.getTransactionReference(),
                customerTransaction.getStatus(),
                customerTransaction.getAmount(),
                customerBalanceAfter,
                merchantUser.getId(),
                merchant.getMerchantNumber(),
                merchant.getBusinessName(),
                customerTransaction.getCreatedAt()
        );
    }

    private User currentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));
    }

    private IdempotencyKey reserveOrValidateIdempotency(User customer, String key, String requestHash) {
        return idempotencyKeyService.findForUser(customer.getId(), key)
                .map(existing -> validateExistingIdempotency(existing, requestHash))
                .orElseGet(() -> idempotencyKeyService.reserve(
                        customer,
                        key,
                        requestHash,
                        IdempotencyOperationType.MERCHANT_PAYMENT,
                        Instant.now().plus(IDEMPOTENCY_EXPIRY_HOURS, ChronoUnit.HOURS)
                ));
    }

    private IdempotencyKey validateExistingIdempotency(IdempotencyKey existing, String requestHash) {
        if (!existing.getRequestHash().equals(requestHash)) {
            throw new IllegalArgumentException("Idempotency key was already used for a different Merchant Payment request.");
        }
        if (existing.getStatus() == IdempotencyStatus.PROCESSING) {
            throw new IllegalArgumentException("The same Merchant Payment request is already processing.");
        }
        if (existing.getStatus() == IdempotencyStatus.FAILED) {
            throw new IllegalArgumentException("The previous Merchant Payment attempt failed. Use a new idempotency key.");
        }
        return existing;
    }

    private MerchantPaymentResponse completedResponse(
            IdempotencyKey idempotencyKey,
            BigDecimal amount,
            Merchant merchant
    ) {
        return new MerchantPaymentResponse(
                true,
                "Merchant Payment request was already completed.",
                completedTransactionReference(idempotencyKey),
                TransactionStatus.SUCCESS,
                amount,
                completedCustomerBalanceAfter(idempotencyKey),
                merchant.getUser().getId(),
                merchant.getMerchantNumber(),
                merchant.getBusinessName(),
                null
        );
    }

    private MerchantPaymentResponse failedResponse(String message, BigDecimal amount, Merchant merchant) {
        return new MerchantPaymentResponse(
                false,
                message,
                null,
                TransactionStatus.FAILED,
                amount,
                null,
                merchant.getUser().getId(),
                merchant.getMerchantNumber(),
                merchant.getBusinessName(),
                null
        );
    }

    private void ensureActiveUser(User user, String message) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new IllegalArgumentException(message);
        }
    }

    private void ensureActiveMerchant(Merchant merchant) {
        if (merchant.getStatus() != MerchantStatus.ACTIVE) {
            throw new IllegalArgumentException("Merchant account is not active.");
        }
    }

    private void ensureNotPayingOwnMerchant(User customer, User merchantUser) {
        if (customer.getId().equals(merchantUser.getId())) {
            throw new IllegalArgumentException("Customer cannot pay their own merchant account.");
        }
    }

    private void ensureActiveWallet(Wallet wallet, String message) {
        if (wallet.getStatus() != WalletStatus.ACTIVE) {
            throw new IllegalArgumentException(message);
        }
    }

    private void ensureSufficientBalance(Wallet customerWallet, BigDecimal amount) {
        if (customerWallet.getBalance().compareTo(amount) < 0) {
            throw new IllegalArgumentException("Customer wallet has insufficient balance.");
        }
    }

    private String uniqueTransactionReference(String prefix) {
        String reference;
        do {
            reference = prefix + "-" + UUID.randomUUID().toString().replace("-", "").substring(0, 24).toUpperCase();
        } while (transactionRecordRepository.existsByTransactionReference(reference));
        return reference;
    }

    private String description(String note, Merchant merchant) {
        String base = "Merchant Payment to " + merchant.getBusinessName() + " (" + merchant.getMerchantNumber() + ")";
        if (note == null || note.isBlank()) {
            return base;
        }
        return base + ". Note: " + note.trim();
    }

    private String requestHash(MerchantPaymentRequest request) {
        return sha256(request.merchantNumber().trim() + ":" + request.amount() + ":" + nullToEmpty(request.note()));
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

    private BigDecimal completedCustomerBalanceAfter(IdempotencyKey idempotencyKey) {
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
