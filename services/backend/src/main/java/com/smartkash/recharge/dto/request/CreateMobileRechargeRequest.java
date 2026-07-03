package com.smartkash.recharge.dto.request;

import com.smartkash.recharge.enums.MobileOperator;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

import java.math.BigDecimal;

public record CreateMobileRechargeRequest(
        @NotNull(message = "Operator is required.")
        MobileOperator operator,

        @NotBlank(message = "Mobile number is required.")
        @Pattern(regexp = "^[0-9]{10,15}$", message = "Mobile number must contain 10 to 15 digits.")
        String mobileNumber,

        @NotNull(message = "Amount is required.")
        @DecimalMin(value = "1.00", message = "Amount must be at least 1.00.")
        BigDecimal amount
) {
}
