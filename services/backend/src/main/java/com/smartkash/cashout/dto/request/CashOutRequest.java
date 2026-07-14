package com.smartkash.cashout.dto.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record CashOutRequest(
        @NotBlank(message = "Agent number is required.")
        @Size(max = 20, message = "Agent number must be 20 characters or fewer.")
        String agentNumber,

        @NotNull(message = "Amount is required.")
        @DecimalMin(value = "1.00", message = "Amount must be at least 1.00.")
        @Digits(integer = 17, fraction = 2, message = "Amount must have up to 17 digits and 2 decimal places.")
        BigDecimal amount,

        @NotBlank(message = "PIN is required.")
        @Pattern(regexp = "\\d{5}", message = "PIN must be exactly 5 digits.")
        String pin,

        @NotBlank(message = "Idempotency key is required.")
        @Size(max = 128, message = "Idempotency key must be 128 characters or fewer.")
        String idempotencyKey,

        @Size(max = 120, message = "Note must be 120 characters or fewer.")
        String note
) {
}
