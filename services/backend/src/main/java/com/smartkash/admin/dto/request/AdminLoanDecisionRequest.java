package com.smartkash.admin.dto.request;

import jakarta.validation.constraints.Size;

public record AdminLoanDecisionRequest(
        @Size(max = 255, message = "Note must be 255 characters or less.")
        String note
) {
}
