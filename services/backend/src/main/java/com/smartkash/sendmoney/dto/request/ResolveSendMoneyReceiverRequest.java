package com.smartkash.sendmoney.dto.request;

import jakarta.validation.constraints.Size;

public record ResolveSendMoneyReceiverRequest(
        @Size(max = 32, message = "Mobile number must be 32 characters or fewer.")
        String mobileNumber,

        @Size(max = 255, message = "QR payload must be 255 characters or fewer.")
        String qrPayload
) {
}
