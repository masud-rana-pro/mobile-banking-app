package com.smartkash.loan.dto.response;

import com.smartkash.loan.enums.LoanStatus;

import java.math.BigDecimal;
import java.time.Instant;

public record LoanRequestResponse(
        Long id,
        BigDecimal amount,
        String purpose,
        LoanStatus status,
        Instant reviewedAt,
        Instant createdAt,
        Instant updatedAt
) {
}
