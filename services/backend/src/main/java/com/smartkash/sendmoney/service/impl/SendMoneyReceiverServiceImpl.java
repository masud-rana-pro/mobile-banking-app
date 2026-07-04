package com.smartkash.sendmoney.service.impl;

import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.sendmoney.dto.request.ResolveSendMoneyReceiverRequest;
import com.smartkash.sendmoney.dto.response.SendMoneyReceiverResponse;
import com.smartkash.sendmoney.mapper.SendMoneyReceiverMapper;
import com.smartkash.sendmoney.service.SendMoneyReceiverService;
import com.smartkash.user.entity.User;
import com.smartkash.user.enums.UserStatus;
import com.smartkash.user.repository.UserRepository;
import com.smartkash.wallet.entity.Wallet;
import com.smartkash.wallet.enums.WalletStatus;
import com.smartkash.wallet.repository.WalletRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SendMoneyReceiverServiceImpl implements SendMoneyReceiverService {

    private static final String QR_PREFIX = "SMARTKASH_USER:";

    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final SendMoneyReceiverMapper sendMoneyReceiverMapper;

    public SendMoneyReceiverServiceImpl(
            UserRepository userRepository,
            WalletRepository walletRepository,
            SendMoneyReceiverMapper sendMoneyReceiverMapper
    ) {
        this.userRepository = userRepository;
        this.walletRepository = walletRepository;
        this.sendMoneyReceiverMapper = sendMoneyReceiverMapper;
    }

    @Override
    @Transactional(readOnly = true)
    public SendMoneyReceiverResponse resolveReceiver(
            JwtPrincipal principal,
            ResolveSendMoneyReceiverRequest request
    ) {
        User sender = currentUser(principal);
        ensureActiveUser(sender, "Only active users can resolve a Send Money receiver.");

        String receiverMobileNumber = resolveReceiverMobileNumber(request);
        User receiver = userRepository.findByMobileNumber(receiverMobileNumber)
                .orElseThrow(() -> new ResourceNotFoundException("Receiver account was not found."));

        ensureNotSelfTransfer(sender, receiver);
        ensureActiveUser(receiver, "Receiver account is not active.");

        Wallet receiverWallet = walletRepository.findByUserId(receiver.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Receiver wallet was not found."));
        ensureActiveWallet(receiverWallet);

        return sendMoneyReceiverMapper.toResponse(receiver, receiverWallet);
    }

    private User currentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));
    }

    private String resolveReceiverMobileNumber(ResolveSendMoneyReceiverRequest request) {
        boolean hasMobileNumber = hasText(request.mobileNumber());
        boolean hasQrPayload = hasText(request.qrPayload());

        if (hasMobileNumber == hasQrPayload) {
            throw new IllegalArgumentException("Provide either mobileNumber or qrPayload, but not both.");
        }

        if (hasMobileNumber) {
            return normalizeMobileNumber(request.mobileNumber());
        }

        return mobileNumberFromQrPayload(request.qrPayload());
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
        String normalized = mobileNumber.trim();
        if (!normalized.matches("^[0-9]{10,15}$")) {
            throw new IllegalArgumentException("Receiver mobile number must contain 10 to 15 digits.");
        }
        return normalized;
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

    private void ensureActiveWallet(Wallet wallet) {
        if (wallet.getStatus() != WalletStatus.ACTIVE) {
            throw new IllegalArgumentException("Receiver wallet is not active.");
        }
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
