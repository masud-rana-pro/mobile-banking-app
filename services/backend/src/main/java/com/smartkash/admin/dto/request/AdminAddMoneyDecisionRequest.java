package com.smartkash.admin.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminAddMoneyDecisionRequest(
        @NotBlank(message = "Idempotency key is required.")
        @Size(max = 128, message = "Idempotency key must be 128 characters or less.")
        String idempotencyKey,

        @Size(max = 255, message = "Note must be 255 characters or less.")
        String note
) {
}
