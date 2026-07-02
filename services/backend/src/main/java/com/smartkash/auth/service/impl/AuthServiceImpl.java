package com.smartkash.auth.service.impl;

import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import com.smartkash.auth.dto.request.FirebaseLoginRequest;
import com.smartkash.auth.dto.request.SetPinRequest;
import com.smartkash.auth.dto.request.VerifyPinRequest;
import com.smartkash.auth.dto.response.AuthTokenResponse;
import com.smartkash.auth.dto.response.PinSetupResponse;
import com.smartkash.auth.dto.response.PinVerificationResponse;
import com.smartkash.auth.service.AuthService;
import com.smartkash.common.exception.AuthException;
import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.firebase.FirebaseTokenVerifier;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.security.JwtService;
import com.smartkash.security.JwtToken;
import com.smartkash.user.entity.User;
import com.smartkash.user.enums.UserRole;
import com.smartkash.user.enums.UserStatus;
import com.smartkash.user.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

@Service
public class AuthServiceImpl implements AuthService {

    private static final String PHONE_NUMBER_CLAIM = "phone_number";
    private static final int MAX_PIN_ATTEMPTS = 5;
    private static final int PIN_BLOCK_MINUTES = 15;

    private final FirebaseTokenVerifier firebaseTokenVerifier;
    private final JwtService jwtService;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public AuthServiceImpl(
            FirebaseTokenVerifier firebaseTokenVerifier,
            JwtService jwtService,
            UserRepository userRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.firebaseTokenVerifier = firebaseTokenVerifier;
        this.jwtService = jwtService;
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
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

    @Override
    @Transactional
    public PinSetupResponse setPin(JwtPrincipal principal, SetPinRequest request) {
        if (!request.pin().equals(request.confirmPin())) {
            throw new IllegalArgumentException("PIN and confirm PIN must match.");
        }

        User user = userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));

        user.setPinHash(passwordEncoder.encode(request.pin()));
        User savedUser = userRepository.save(user);

        return new PinSetupResponse(savedUser.isPinSet(), savedUser.getPinUpdatedAt());
    }

    @Override
    @Transactional
    public PinVerificationResponse verifyPin(JwtPrincipal principal, VerifyPinRequest request) {
        User user = currentUser(principal);
        Instant now = Instant.now();

        if (!user.isPinSet() || user.getPinHash() == null) {
            throw new IllegalArgumentException("PIN is not set.");
        }

        if (user.getPinBlockedUntil() != null && user.getPinBlockedUntil().isAfter(now)) {
            return pinVerificationResponse(false, user);
        }

        if (passwordEncoder.matches(request.pin(), user.getPinHash())) {
            user.resetPinFailures();
            User savedUser = userRepository.save(user);
            return pinVerificationResponse(true, savedUser);
        }

        user.recordWrongPinAttempt(MAX_PIN_ATTEMPTS, now.plus(PIN_BLOCK_MINUTES, ChronoUnit.MINUTES));
        User savedUser = userRepository.save(user);
        return pinVerificationResponse(false, savedUser);
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

    private User currentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));
    }

    private User createUser(String firebaseUid, String phoneNumber) {
        userRepository.findByMobileNumber(phoneNumber)
                .ifPresent(existingUser -> {
                    throw new AuthException("Mobile number is already linked to another account.");
                });

        User user = new User(firebaseUid, phoneNumber, UserRole.CUSTOMER, UserStatus.ACTIVE);
        return userRepository.save(user);
    }

    private PinVerificationResponse pinVerificationResponse(boolean verified, User user) {
        int remainingAttempts = Math.max(0, MAX_PIN_ATTEMPTS - user.getPinFailedAttempts());
        return new PinVerificationResponse(verified, remainingAttempts, user.getPinBlockedUntil());
    }
}
