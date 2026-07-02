package com.smartkash.security;

import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

class JwtServiceTests {

    @Test
    void generateAndParseTokenKeepsExpectedClaims() {
        JwtProperties properties = new JwtProperties("01234567890123456789012345678901", 60);
        JwtService jwtService = new JwtService(properties);
        Instant beforeGenerate = Instant.now();

        JwtToken jwtToken = jwtService.generateToken("+8801555555555", "+8801555555555", "CUSTOMER");
        JwtPrincipal principal = jwtService.parseToken(jwtToken.accessToken());

        assertThat(principal.firebaseUid()).isEqualTo("+8801555555555");
        assertThat(principal.phoneNumber()).isEqualTo("+8801555555555");
        assertThat(principal.role()).isEqualTo("CUSTOMER");
        assertThat(jwtToken.expiresAt()).isAfterOrEqualTo(beforeGenerate.plusSeconds(59 * 60));
        assertThat(jwtToken.expiresAt()).isBeforeOrEqualTo(beforeGenerate.plusSeconds(61 * 60));
    }
}
