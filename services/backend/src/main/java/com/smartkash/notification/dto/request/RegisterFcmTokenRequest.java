package com.smartkash.notification.dto.request;

import com.smartkash.notification.enums.DeviceType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record RegisterFcmTokenRequest(
        @NotBlank(message = "FCM token is required.")
        @Size(max = 500, message = "FCM token must be 500 characters or fewer.")
        String fcmToken,

        @NotNull(message = "Device type is required.")
        DeviceType deviceType
) {
}
