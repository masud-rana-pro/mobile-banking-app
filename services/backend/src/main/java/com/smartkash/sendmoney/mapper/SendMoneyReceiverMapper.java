package com.smartkash.sendmoney.mapper;

import com.smartkash.sendmoney.dto.response.SendMoneyReceiverResponse;
import com.smartkash.user.entity.User;
import com.smartkash.user.entity.UserProfile;
import com.smartkash.wallet.entity.Wallet;
import org.springframework.stereotype.Component;

@Component
public class SendMoneyReceiverMapper {

    public SendMoneyReceiverResponse toResponse(User receiver, Wallet receiverWallet) {
        return new SendMoneyReceiverResponse(
                receiver.getId(),
                receiver.getMobileNumber(),
                displayName(receiver),
                receiver.getRole(),
                receiver.getStatus(),
                receiverWallet.getStatus()
        );
    }

    private String displayName(User receiver) {
        UserProfile profile = receiver.getProfile();
        if (profile == null || profile.getFullName() == null || profile.getFullName().isBlank()) {
            return null;
        }
        return profile.getFullName();
    }
}
