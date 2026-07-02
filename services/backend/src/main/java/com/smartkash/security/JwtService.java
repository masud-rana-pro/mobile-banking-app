package com.smartkash.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;

@Service
public class JwtService {

    private static final String PHONE_NUMBER_CLAIM = "phone_number";
    private static final String ROLE_CLAIM = "role";
    private static final int MIN_SECRET_BYTES = 32;

    private final JwtProperties jwtProperties;
    private final Clock clock;

    @Autowired
    public JwtService(JwtProperties jwtProperties) {
        this(jwtProperties, Clock.systemUTC());
    }

    JwtService(JwtProperties jwtProperties, Clock clock) {
        this.jwtProperties = jwtProperties;
        this.clock = clock;
    }

    public JwtToken generateToken(String firebaseUid, String phoneNumber, String role) {
        Instant issuedAt = Instant.now(clock);
        Instant expiresAt = issuedAt.plus(jwtProperties.expirationMinutes(), ChronoUnit.MINUTES);

        String token = Jwts.builder()
                .subject(firebaseUid)
                .claim(PHONE_NUMBER_CLAIM, phoneNumber)
                .claim(ROLE_CLAIM, role)
                .issuedAt(Date.from(issuedAt))
                .expiration(Date.from(expiresAt))
                .signWith(secretKey())
                .compact();

        return new JwtToken(token, expiresAt);
    }

    public JwtPrincipal parseToken(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(secretKey())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

            return new JwtPrincipal(
                    claims.getSubject(),
                    claims.get(PHONE_NUMBER_CLAIM, String.class),
                    claims.get(ROLE_CLAIM, String.class)
            );
        } catch (JwtException | IllegalArgumentException exception) {
            throw new IllegalArgumentException("Invalid backend JWT.", exception);
        }
    }

    private SecretKey secretKey() {
        byte[] keyBytes = jwtProperties.secret().getBytes(StandardCharsets.UTF_8);
        if (keyBytes.length < MIN_SECRET_BYTES) {
            throw new IllegalArgumentException("JWT secret must be at least 32 bytes.");
        }

        return Keys.hmacShaKeyFor(keyBytes);
    }
}
