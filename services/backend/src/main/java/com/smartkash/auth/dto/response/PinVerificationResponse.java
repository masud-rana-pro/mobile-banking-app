package com.smartkash.auth.dto.response;

import java.time.Instant;

public record PinVerificationResponse(
        boolean verified,
        int remainingAttempts,
        Instant blockedUntil
) {
}
