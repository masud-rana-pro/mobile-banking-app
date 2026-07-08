package com.smartkash.user.dto.response;

import com.smartkash.user.enums.UserRole;
import com.smartkash.user.enums.UserStatus;

import java.time.Instant;

public record UserResponse(
        Long id,
        String firebaseUid,
        String mobileNumber,
        UserRole role,
        UserStatus status,
        boolean pinSet,
        Instant pinUpdatedAt,
        UserProfileResponse profile,
        Instant createdAt,
        Instant updatedAt
) {
}
