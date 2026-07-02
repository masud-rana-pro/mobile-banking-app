package com.smartkash.auth.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record SetPinRequest(
        @NotBlank(message = "PIN is required.")
        @Pattern(regexp = "\\d{5}", message = "PIN must be exactly 5 digits.")
        String pin,

        @NotBlank(message = "Confirm PIN is required.")
        @Pattern(regexp = "\\d{5}", message = "Confirm PIN must be exactly 5 digits.")
        String confirmPin
) {
}
