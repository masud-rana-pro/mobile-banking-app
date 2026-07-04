package com.smartkash.savings.dto.response;

import com.smartkash.transaction.enums.TransactionStatus;

import java.math.BigDecimal;
import java.time.Instant;

public record SavingsDepositResponse(
        boolean success,
        String message,
        String transactionReference,
        TransactionStatus status,
        BigDecimal amount,
        BigDecimal walletBalanceAfter,
        SavingsGoalResponse goal,
        Instant createdAt
) {
}
