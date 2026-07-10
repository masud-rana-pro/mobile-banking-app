package com.smartkash.user.dto.response;

public record UserProfileResponse(
        String fullName,
        String email,
        String avatarImageId,
        String avatarUrl
) {
}
