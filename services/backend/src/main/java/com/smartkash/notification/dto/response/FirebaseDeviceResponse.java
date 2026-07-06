package com.smartkash.notification.dto.response;

import com.smartkash.notification.enums.DeviceType;

import java.time.Instant;

public record FirebaseDeviceResponse(
        Long id,
        DeviceType deviceType,
        boolean active,
        Instant createdAt,
        Instant updatedAt
) {
}
