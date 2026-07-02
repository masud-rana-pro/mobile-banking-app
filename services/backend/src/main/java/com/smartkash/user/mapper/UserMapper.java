package com.smartkash.user.mapper;

import com.smartkash.user.dto.response.UserProfileResponse;
import com.smartkash.user.dto.response.UserResponse;
import com.smartkash.user.entity.User;
import com.smartkash.user.entity.UserProfile;
import org.springframework.stereotype.Component;

@Component
public class UserMapper {

    public UserResponse toResponse(User user) {
        return toResponse(user, user.getProfile());
    }

    public UserResponse toResponse(User user, UserProfile profile) {
        return new UserResponse(
                user.getId(),
                user.getFirebaseUid(),
                user.getMobileNumber(),
                user.getRole(),
                user.getStatus(),
                toProfileResponse(profile),
                user.getCreatedAt(),
                user.getUpdatedAt()
        );
    }

    private UserProfileResponse toProfileResponse(UserProfile profile) {
        if (profile == null) {
            return null;
        }

        return new UserProfileResponse(
                profile.getFullName(),
                profile.getEmail(),
                profile.getAvatarUrl()
        );
    }
}
