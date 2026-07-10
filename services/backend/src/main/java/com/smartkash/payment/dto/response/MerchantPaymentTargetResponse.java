package com.smartkash.payment.dto.response;

import com.smartkash.merchant.enums.MerchantStatus;

public record MerchantPaymentTargetResponse(
        Long merchantUserId,
        String merchantNumber,
        String businessName,
        String businessType,
        MerchantStatus status
) {
}
