package com.smartkash.auth.controller;

import com.smartkash.auth.dto.request.FirebaseLoginRequest;
import com.smartkash.auth.dto.response.AuthTokenResponse;
import com.smartkash.auth.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
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
}
