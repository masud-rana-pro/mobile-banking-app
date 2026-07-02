package com.smartkash.auth.dto.request;

import jakarta.validation.constraints.NotBlank;

public record FirebaseLoginRequest(
        @NotBlank(message = "Firebase ID token is required.")
        String firebaseIdToken
) {
}
