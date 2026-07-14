package com.smartkash.addmoney.dto.response;

import com.smartkash.addmoney.enums.AddMoneySourceType;
import com.smartkash.addmoney.enums.AddMoneyStatus;

import java.math.BigDecimal;
import java.time.Instant;

public record AddMoneyRequestResponse(
        Long id,
        BigDecimal amount,
        AddMoneySourceType sourceType,
        AddMoneyStatus status,
        String note,
        String transactionReference,
        BigDecimal balanceAfter,
        Instant approvedAt,
        Instant createdAt,
        Instant updatedAt
) {
}
