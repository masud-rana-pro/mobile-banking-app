package com.smartkash.loan.dto.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record CreateLoanRequest(
        @NotNull(message = "Amount is required.")
        @DecimalMin(value = "1.00", message = "Amount must be at least 1.00.")
        BigDecimal amount,

        @NotBlank(message = "Purpose is required.")
        @Size(max = 255, message = "Purpose must be 255 characters or less.")
        String purpose
) {
}
