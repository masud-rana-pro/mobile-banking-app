package com.smartkash.transaction.mapper;

import com.smartkash.transaction.dto.response.TransactionResponse;
import com.smartkash.transaction.entity.TransactionRecord;
import com.smartkash.user.entity.User;
import com.smartkash.user.entity.UserProfile;
import org.springframework.stereotype.Component;

@Component
public class TransactionRecordMapper {

    public TransactionResponse toResponse(TransactionRecord transaction) {
        User counterparty = transaction.getCounterpartyUser();
        return new TransactionResponse(
                transaction.getId(),
                transaction.getTransactionReference(),
                transaction.getType(),
                transaction.getStatus(),
                transaction.getAmount(),
                counterparty == null ? null : counterparty.getId(),
                counterparty == null ? null : counterparty.getMobileNumber(),
                avatarUrl(transaction.getUser()),
                counterparty == null ? null : avatarUrl(counterparty),
                transaction.getDescription(),
                transaction.getCreatedAt()
        );
    }

    private String avatarUrl(User user) {
        if (user == null) {
            return null;
        }

        UserProfile profile = user.getProfile();
        if (profile == null) {
            return null;
        }

        if (profile.getAvatarImageId() != null && !profile.getAvatarImageId().isBlank()) {
            return "/api/users/profile-images/" + profile.getAvatarImageId();
        }

        return profile.getAvatarUrl();
    }
}
