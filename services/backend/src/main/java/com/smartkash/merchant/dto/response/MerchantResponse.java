package com.smartkash.merchant.dto.response;

import com.smartkash.merchant.enums.MerchantStatus;

import java.time.Instant;

public record MerchantResponse(
        Long id,
        Long userId,
        String businessName,
        String merchantNumber,
        String businessType,
        MerchantStatus status,
        Instant createdAt,
        Instant updatedAt
) {
}
