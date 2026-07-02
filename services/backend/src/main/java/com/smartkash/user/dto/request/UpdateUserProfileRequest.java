package com.smartkash.user.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;

public record UpdateUserProfileRequest(
        @Size(max = 120, message = "Full name must be at most 120 characters.")
        String fullName,

        @Email(message = "Email must be valid.")
        @Size(max = 160, message = "Email must be at most 160 characters.")
        String email,

        @Size(max = 500, message = "Avatar URL must be at most 500 characters.")
        String avatarUrl
) {
}
