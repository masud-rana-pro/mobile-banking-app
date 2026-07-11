package com.smartkash.paybill.dto.response;

import com.smartkash.transaction.enums.TransactionStatus;

import java.math.BigDecimal;
import java.time.Instant;

public record PayBillResponse(
        boolean success,
        String message,
        String transactionReference,
        TransactionStatus status,
        BigDecimal amount,
        BigDecimal balanceAfter,
        String billerCode,
        String billAccountNumber,
        Instant createdAt
) {
}
