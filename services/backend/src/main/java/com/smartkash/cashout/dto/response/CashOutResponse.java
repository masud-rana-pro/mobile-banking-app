package com.smartkash.cashout.dto.response;

import com.smartkash.transaction.enums.TransactionStatus;

import java.math.BigDecimal;
import java.time.Instant;

public record CashOutResponse(
        boolean success,
        String message,
        String transactionReference,
        TransactionStatus status,
        BigDecimal amount,
        BigDecimal chargeAmount,
        BigDecimal balanceAfter,
        String agentNumber,
        Instant createdAt
) {
}
