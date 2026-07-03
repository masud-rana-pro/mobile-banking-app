package com.smartkash.merchant.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record CreateMerchantRequest(
        @NotBlank(message = "Business name is required.")
        @Size(max = 120, message = "Business name must be 120 characters or less.")
        String businessName,

        @NotBlank(message = "Merchant number is required.")
        @Pattern(regexp = "^[0-9]{8,16}$", message = "Merchant number must be 8 to 16 digits.")
        String merchantNumber,

        @NotBlank(message = "Business type is required.")
        @Size(max = 80, message = "Business type must be 80 characters or less.")
        String businessType
) {
}
