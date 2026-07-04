package com.smartkash.payment.dto.response;

import com.smartkash.transaction.enums.TransactionStatus;

import java.math.BigDecimal;
import java.time.Instant;

public record MerchantPaymentResponse(
        boolean success,
        String message,
        String transactionReference,
        TransactionStatus status,
        BigDecimal amount,
        BigDecimal customerBalanceAfter,
        Long merchantUserId,
        String merchantNumber,
        String businessName,
        Instant createdAt
) {
}
