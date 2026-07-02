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
import com.smartkash.user.entity.User;
import com.smartkash.user.enums.UserRole;
import com.smartkash.user.enums.UserStatus;
import com.smartkash.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthServiceImpl implements AuthService {

    private static final String PHONE_NUMBER_CLAIM = "phone_number";

    private final FirebaseTokenVerifier firebaseTokenVerifier;
    private final JwtService jwtService;
    private final UserRepository userRepository;

    public AuthServiceImpl(
            FirebaseTokenVerifier firebaseTokenVerifier,
            JwtService jwtService,
            UserRepository userRepository
    ) {
        this.firebaseTokenVerifier = firebaseTokenVerifier;
        this.jwtService = jwtService;
        this.userRepository = userRepository;
    }

    @Override
    @Transactional
    public AuthTokenResponse loginWithFirebase(FirebaseLoginRequest request) {
        FirebaseToken firebaseToken = verifyFirebaseToken(request.firebaseIdToken());
        String phoneNumber = phoneNumber(firebaseToken);
        User user = findOrCreateUser(firebaseToken.getUid(), phoneNumber);
        String role = user.getRole().name();
        JwtToken jwtToken = jwtService.generateToken(user.getFirebaseUid(), user.getMobileNumber(), role);

        return new AuthTokenResponse(
                "Bearer",
                jwtToken.accessToken(),
                jwtToken.expiresAt(),
                user.getFirebaseUid(),
                user.getMobileNumber(),
                role
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
        if (phoneNumber == null || phoneNumber.toString().isBlank()) {
            throw new AuthException("Firebase phone number is required.");
        }

        return phoneNumber.toString();
    }

    private User findOrCreateUser(String firebaseUid, String phoneNumber) {
        return userRepository.findByFirebaseUid(firebaseUid)
                .orElseGet(() -> createUser(firebaseUid, phoneNumber));
    }

    private User createUser(String firebaseUid, String phoneNumber) {
        userRepository.findByMobileNumber(phoneNumber)
                .ifPresent(existingUser -> {
                    throw new AuthException("Mobile number is already linked to another account.");
                });

        User user = new User(firebaseUid, phoneNumber, UserRole.CUSTOMER, UserStatus.ACTIVE);
        return userRepository.save(user);
    }
}
