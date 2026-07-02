package com.smartkash.auth.controller;

import com.smartkash.auth.dto.request.FirebaseLoginRequest;
import com.smartkash.auth.dto.request.SetPinRequest;
import com.smartkash.auth.dto.request.VerifyPinRequest;
import com.smartkash.auth.dto.response.AuthTokenResponse;
import com.smartkash.auth.dto.response.PinSetupResponse;
import com.smartkash.auth.dto.response.PinVerificationResponse;
import com.smartkash.auth.service.AuthService;
import com.smartkash.security.JwtPrincipal;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/firebase-login")
    public ResponseEntity<AuthTokenResponse> firebaseLogin(@Valid @RequestBody FirebaseLoginRequest request) {
        return ResponseEntity.ok(authService.loginWithFirebase(request));
    }

    @PostMapping("/set-pin")
    public ResponseEntity<PinSetupResponse> setPin(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody SetPinRequest request
    ) {
        return ResponseEntity.ok(authService.setPin(principal, request));
    }

    @PostMapping("/verify-pin")
    public ResponseEntity<PinVerificationResponse> verifyPin(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody VerifyPinRequest request
    ) {
        return ResponseEntity.ok(authService.verifyPin(principal, request));
    }
}
