package com.smartkash.transaction.dto.response;

import com.smartkash.transaction.enums.TransactionStatus;
import com.smartkash.transaction.enums.TransactionType;

import java.math.BigDecimal;
import java.time.Instant;

public record TransactionResponse(
        Long id,
        String transactionReference,
        TransactionType type,
        TransactionStatus status,
        BigDecimal amount,
        Long counterpartyUserId,
        String counterpartyMobileNumber,
        String userAvatarUrl,
        String counterpartyAvatarUrl,
        String description,
        Instant createdAt
) {
}
