package com.smartkash.auth.dto.response;

import java.time.Instant;

public record AuthTokenResponse(
        String tokenType,
        String accessToken,
        Instant expiresAt,
        String firebaseUid,
        String phoneNumber,
        String role
) {
}
