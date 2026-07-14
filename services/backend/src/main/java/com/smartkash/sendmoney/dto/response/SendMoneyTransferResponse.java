package com.smartkash.sendmoney.dto.response;

import com.smartkash.transaction.enums.TransactionStatus;

import java.math.BigDecimal;
import java.time.Instant;

public record SendMoneyTransferResponse(
        boolean success,
        String message,
        String transactionReference,
        TransactionStatus status,
        BigDecimal amount,
        BigDecimal chargeAmount,
        BigDecimal senderBalanceAfter,
        Long receiverUserId,
        String receiverMobileNumber,
        Instant createdAt
) {
}
