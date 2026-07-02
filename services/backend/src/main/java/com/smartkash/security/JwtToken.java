package com.smartkash.security;

import java.time.Instant;

public record JwtToken(
        String accessToken,
        Instant expiresAt
) {
}
