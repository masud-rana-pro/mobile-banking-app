package com.smartkash.security;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "smartkash.security.jwt")
public record JwtProperties(
        String secret,
        long expirationMinutes
) {
}
