package com.smartkash.savings.dto.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;

public record CreateSavingsGoalRequest(
        @NotBlank(message = "Savings goal name is required.")
        @Size(max = 100, message = "Savings goal name must be 100 characters or less.")
        String name,

        @NotNull(message = "Target amount is required.")
        @DecimalMin(value = "1.00", message = "Target amount must be at least 1.00.")
        BigDecimal targetAmount,

        @Future(message = "Target date must be in the future.")
        LocalDate targetDate
) {
}
