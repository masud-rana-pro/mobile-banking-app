package com.smartkash.auth.service.impl;

import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import com.smartkash.auth.dto.request.FirebaseLoginRequest;
import com.smartkash.auth.dto.response.AuthTokenResponse;
import com.smartkash.auth.service.AuthService;
import com.smartkash.common.exception.AuthException;
import com.smartkash.firebase.FirebaseTokenVerifier;
import com.smartkash.security.JwtService;
import com.smartkash.security.JwtToken;
import org.springframework.stereotype.Service;

@Service
public class AuthServiceImpl implements AuthService {

    private static final String DEFAULT_ROLE = "CUSTOMER";
    private static final String PHONE_NUMBER_CLAIM = "phone_number";

    private final FirebaseTokenVerifier firebaseTokenVerifier;
    private final JwtService jwtService;

    public AuthServiceImpl(FirebaseTokenVerifier firebaseTokenVerifier, JwtService jwtService) {
        this.firebaseTokenVerifier = firebaseTokenVerifier;
        this.jwtService = jwtService;
    }

    @Override
    public AuthTokenResponse loginWithFirebase(FirebaseLoginRequest request) {
        FirebaseToken firebaseToken = verifyFirebaseToken(request.firebaseIdToken());
        String phoneNumber = phoneNumber(firebaseToken);
        JwtToken jwtToken = jwtService.generateToken(firebaseToken.getUid(), phoneNumber, DEFAULT_ROLE);

        return new AuthTokenResponse(
                "Bearer",
                jwtToken.accessToken(),
                jwtToken.expiresAt(),
                firebaseToken.getUid(),
                phoneNumber,
                DEFAULT_ROLE
        );
    }

    private FirebaseToken verifyFirebaseToken(String firebaseIdToken) {
        try {
            return firebaseTokenVerifier.verifyIdToken(firebaseIdToken);
        } catch (FirebaseAuthException | IllegalStateException exception) {
            throw new AuthException("Invalid Firebase ID token.", exception);
        }
    }

    private String phoneNumber(FirebaseToken firebaseToken) {
        Object phoneNumber = firebaseToken.getClaims().get(PHONE_NUMBER_CLAIM);
        return phoneNumber == null ? null : phoneNumber.toString();
    }
}
