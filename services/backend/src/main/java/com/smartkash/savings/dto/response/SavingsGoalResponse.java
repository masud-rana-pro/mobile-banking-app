package com.smartkash.savings.dto.response;

import com.smartkash.savings.enums.SavingsGoalStatus;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

public record SavingsGoalResponse(
        Long id,
        String name,
        BigDecimal targetAmount,
        BigDecimal currentAmount,
        LocalDate targetDate,
        SavingsGoalStatus status,
        Instant createdAt,
        Instant updatedAt
) {
}
