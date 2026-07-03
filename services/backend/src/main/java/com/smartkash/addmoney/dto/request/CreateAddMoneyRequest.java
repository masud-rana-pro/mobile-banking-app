package com.smartkash.addmoney.dto.request;

import com.smartkash.addmoney.enums.AddMoneySourceType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record CreateAddMoneyRequest(
        @NotNull(message = "Amount is required.")
        @DecimalMin(value = "1.00", message = "Amount must be at least 1.00.")
        BigDecimal amount,

        @NotNull(message = "Source type is required.")
        AddMoneySourceType sourceType,

        @Size(max = 255, message = "Note must be 255 characters or less.")
        String note
) {
}
