package com.smartkash.recharge.dto.response;

import com.smartkash.recharge.enums.MobileOperator;
import com.smartkash.recharge.enums.RechargeStatus;

import java.math.BigDecimal;
import java.time.Instant;

public record MobileRechargeResponse(
        Long id,
        MobileOperator operator,
        String mobileNumber,
        BigDecimal amount,
        RechargeStatus status,
        String transactionReference,
        BigDecimal balanceAfter,
        Instant createdAt
) {
}
