package com.smartkash.sendmoney.service.impl;

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
import com.smartkash.security.JwtPrincipal;
import com.smartkash.sendmoney.dto.request.SendMoneyRequest;
import com.smartkash.sendmoney.dto.response.SendMoneyTransferResponse;
import com.smartkash.sendmoney.service.SendMoneyTransferService;
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
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HexFormat;
import java.util.Map;
import java.util.UUID;

@Service
public class SendMoneyTransferServiceImpl implements SendMoneyTransferService {

    private static final String QR_PREFIX = "SMARTKASH_USER:";
    private static final int IDEMPOTENCY_EXPIRY_HOURS = 24;
    private static final BigDecimal SEND_MONEY_CHARGE_PER_1000 = new BigDecimal("2.00");
    private static final BigDecimal CHARGE_BASE_AMOUNT = new BigDecimal("1000.00");

    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final TransactionRecordRepository transactionRecordRepository;
    private final LedgerEntryRepository ledgerEntryRepository;
    private final IdempotencyKeyService idempotencyKeyService;
    private final AuthService authService;
    private final TransactionAlertService transactionAlertService;

    public SendMoneyTransferServiceImpl(
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
    public SendMoneyTransferResponse sendMoney(JwtPrincipal principal, SendMoneyRequest request) {
        User sender = currentUser(principal);
        ensureActiveUser(sender, "Only active users can send money.");

        String receiverMobileNumber = resolveReceiverMobileNumber(request.mobileNumber(), request.qrPayload());
        User receiver = userRepository.findByMobileNumber(receiverMobileNumber)
                .orElseThrow(() -> new ResourceNotFoundException("Receiver account was not found."));

        ensureNotSelfTransfer(sender, receiver);
        ensureActiveUser(receiver, "Receiver account is not active.");

        PinVerificationResponse pinVerification = authService.verifyPin(principal, new VerifyPinRequest(request.pin()));
        if (!pinVerification.verified()) {
            return failedResponse("PIN verification failed.", request.amount(), receiver);
        }

        String requestHash = requestHash(request, receiverMobileNumber);
        IdempotencyKey idempotencyKey = reserveOrValidateIdempotency(sender, request.idempotencyKey(), requestHash);
        if (idempotencyKey.getStatus() == IdempotencyStatus.COMPLETED) {
            return completedResponse(idempotencyKey, request.amount(), receiver);
        }

        Wallet senderWallet = walletRepository.findByUserIdForUpdate(sender.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Sender wallet was not found."));
        Wallet receiverWallet = walletRepository.findByUserIdForUpdate(receiver.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Receiver wallet was not found."));

        ensureActiveWallet(senderWallet, "Sender wallet is not active.");
        ensureActiveWallet(receiverWallet, "Receiver wallet is not active.");
        BigDecimal chargeAmount = calculateCharge(request.amount());
        BigDecimal totalDebitAmount = request.amount().add(chargeAmount);
        ensureSufficientBalance(senderWallet, totalDebitAmount);

        BigDecimal senderBalanceAfter = senderWallet.debit(totalDebitAmount);
        BigDecimal receiverBalanceAfter = receiverWallet.credit(request.amount());
        String senderTransactionReference = uniqueTransactionReference("SM");
        String receiverTransactionReference = uniqueTransactionReference("RM");
        String description = description(request.note(), sender.getMobileNumber(), receiver.getMobileNumber());

        TransactionRecord senderTransaction = transactionRecordRepository.save(new TransactionRecord(
                senderTransactionReference,
                sender,
                TransactionType.SEND_MONEY,
                TransactionStatus.SUCCESS,
                totalDebitAmount,
                receiver,
                description
        ));
        transactionRecordRepository.save(new TransactionRecord(
                receiverTransactionReference,
                receiver,
                TransactionType.RECEIVE_MONEY,
                TransactionStatus.SUCCESS,
                request.amount(),
                sender,
                description
        ));

        LedgerEntry debitEntry = ledgerEntryRepository.save(new LedgerEntry(
                senderWallet,
                sender,
                senderTransactionReference,
                null,
                LedgerEntryType.DEBIT,
                totalDebitAmount,
                senderBalanceAfter,
                "Send Money wallet debit including charge"
        ));
        LedgerEntry creditEntry = ledgerEntryRepository.save(new LedgerEntry(
                receiverWallet,
                receiver,
                senderTransactionReference,
                debitEntry,
                LedgerEntryType.CREDIT,
                request.amount(),
                receiverBalanceAfter,
                "Send Money wallet credit"
        ));
        debitEntry.linkTo(creditEntry);
        ledgerEntryRepository.save(debitEntry);

        idempotencyKeyService.markCompleted(
                idempotencyKey,
                "SUCCESS:" + senderTransactionReference + ":" + senderBalanceAfter
        );
        transactionAlertService.sendTransactionAlert(
                sender,
                NotificationType.SEND_MONEY,
                "Send Money completed",
                "You sent BDT " + request.amount() + " to " + receiver.getMobileNumber() + ".",
                Map.of("transactionReference", senderTransactionReference, "type", TransactionType.SEND_MONEY.name())
        );
        transactionAlertService.sendTransactionAlert(
                receiver,
                NotificationType.SEND_MONEY,
                "Money received",
                "You received BDT " + request.amount() + " from " + sender.getMobileNumber() + ".",
                Map.of("transactionReference", senderTransactionReference, "type", TransactionType.RECEIVE_MONEY.name())
        );

        return new SendMoneyTransferResponse(
                true,
                "Send Money completed successfully.",
                senderTransaction.getTransactionReference(),
                senderTransaction.getStatus(),
                request.amount(),
                chargeAmount,
                senderBalanceAfter,
                receiver.getId(),
                receiver.getMobileNumber(),
                senderTransaction.getCreatedAt()
        );
    }

    private User currentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));
    }

    private IdempotencyKey reserveOrValidateIdempotency(User sender, String key, String requestHash) {
        return idempotencyKeyService.findForUser(sender.getId(), key)
                .map(existing -> validateExistingIdempotency(existing, requestHash))
                .orElseGet(() -> idempotencyKeyService.reserve(
                        sender,
                        key,
                        requestHash,
                        IdempotencyOperationType.SEND_MONEY,
                        Instant.now().plus(IDEMPOTENCY_EXPIRY_HOURS, ChronoUnit.HOURS)
                ));
    }

    private IdempotencyKey validateExistingIdempotency(IdempotencyKey existing, String requestHash) {
        if (!existing.getRequestHash().equals(requestHash)) {
            throw new IllegalArgumentException("Idempotency key was already used for a different Send Money request.");
        }
        if (existing.getStatus() == IdempotencyStatus.PROCESSING) {
            throw new IllegalArgumentException("The same Send Money request is already processing.");
        }
        if (existing.getStatus() == IdempotencyStatus.FAILED) {
            throw new IllegalArgumentException("The previous Send Money request attempt failed. Use a new idempotency key.");
        }
        return existing;
    }

    private SendMoneyTransferResponse completedResponse(
            IdempotencyKey idempotencyKey,
            BigDecimal amount,
            User receiver
    ) {
        String transactionReference = completedTransactionReference(idempotencyKey);
        BigDecimal senderBalanceAfter = completedSenderBalanceAfter(idempotencyKey);
        return new SendMoneyTransferResponse(
                true,
                "Send Money request was already completed.",
                transactionReference,
                TransactionStatus.SUCCESS,
                amount,
                calculateCharge(amount),
                senderBalanceAfter,
                receiver.getId(),
                receiver.getMobileNumber(),
                null
        );
    }

    private SendMoneyTransferResponse failedResponse(String message, BigDecimal amount, User receiver) {
        return new SendMoneyTransferResponse(
                false,
                message,
                null,
                TransactionStatus.FAILED,
                amount,
                null,
                null,
                receiver.getId(),
                receiver.getMobileNumber(),
                null
        );
    }

    private String resolveReceiverMobileNumber(String mobileNumber, String qrPayload) {
        boolean hasMobileNumber = hasText(mobileNumber);
        boolean hasQrPayload = hasText(qrPayload);

        if (hasMobileNumber == hasQrPayload) {
            throw new IllegalArgumentException("Provide either mobileNumber or qrPayload, but not both.");
        }

        if (hasMobileNumber) {
            return normalizeMobileNumber(mobileNumber);
        }

        return mobileNumberFromQrPayload(qrPayload);
    }

    private String mobileNumberFromQrPayload(String qrPayload) {
        String trimmedPayload = qrPayload.trim();
        if (!trimmedPayload.startsWith(QR_PREFIX)) {
            throw new IllegalArgumentException("Invalid SmartKash receiver QR payload.");
        }

        String mobileNumber = trimmedPayload.substring(QR_PREFIX.length());
        if (!hasText(mobileNumber)) {
            throw new IllegalArgumentException("Receiver QR payload does not contain a mobile number.");
        }

        return normalizeMobileNumber(mobileNumber);
    }

    private String normalizeMobileNumber(String mobileNumber) {
        String normalized = mobileNumber.trim().replace(" ", "").replace("-", "");
        if (normalized.startsWith("+880") && normalized.matches("^\\+8801[0-9]{9}$")) {
            return normalized;
        }
        if (normalized.startsWith("880") && normalized.matches("^8801[0-9]{9}$")) {
            return "+" + normalized;
        }
        if (normalized.startsWith("01") && normalized.matches("^01[0-9]{9}$")) {
            return "+88" + normalized;
        }
        if (normalized.startsWith("1") && normalized.matches("^1[0-9]{9}$")) {
            return "+880" + normalized;
        }
        throw new IllegalArgumentException("Receiver mobile number must be a valid Bangladesh mobile number.");
    }

    private void ensureNotSelfTransfer(User sender, User receiver) {
        if (sender.getId().equals(receiver.getId())) {
            throw new IllegalArgumentException("Sender and receiver cannot be the same account.");
        }
    }

    private void ensureActiveUser(User user, String message) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new IllegalArgumentException(message);
        }
    }

    private void ensureActiveWallet(Wallet wallet, String message) {
        if (wallet.getStatus() != WalletStatus.ACTIVE) {
            throw new IllegalArgumentException(message);
        }
    }

    private void ensureSufficientBalance(Wallet senderWallet, BigDecimal totalDebitAmount) {
        if (senderWallet.getBalance().compareTo(totalDebitAmount) < 0) {
            throw new IllegalArgumentException("Sender wallet has insufficient balance.");
        }
    }

    private BigDecimal calculateCharge(BigDecimal amount) {
        return amount
                .multiply(SEND_MONEY_CHARGE_PER_1000)
                .divide(CHARGE_BASE_AMOUNT, 2, RoundingMode.HALF_UP);
    }

    private String uniqueTransactionReference(String prefix) {
        String reference;
        do {
            reference = prefix + "-" + UUID.randomUUID().toString().replace("-", "").substring(0, 24).toUpperCase();
        } while (transactionRecordRepository.existsByTransactionReference(reference));
        return reference;
    }

    private String description(String note, String senderMobileNumber, String receiverMobileNumber) {
        String base = "Send Money from " + senderMobileNumber + " to " + receiverMobileNumber;
        if (!hasText(note)) {
            return base;
        }
        return base + ". Note: " + note.trim();
    }

    private String requestHash(SendMoneyRequest request, String receiverMobileNumber) {
        return sha256(receiverMobileNumber + ":" + request.amount() + ":" + nullToEmpty(request.note()));
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

    private BigDecimal completedSenderBalanceAfter(IdempotencyKey idempotencyKey) {
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

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
