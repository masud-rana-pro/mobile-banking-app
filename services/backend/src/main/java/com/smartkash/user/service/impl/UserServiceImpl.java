package com.smartkash.user.service.impl;

import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.dto.request.UpdateUserProfileRequest;
import com.smartkash.user.dto.response.UserResponse;
import com.smartkash.user.entity.User;
import com.smartkash.user.entity.UserProfile;
import com.smartkash.user.mapper.UserMapper;
import com.smartkash.user.repository.UserProfileRepository;
import com.smartkash.user.repository.UserRepository;
import com.smartkash.user.service.UserService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final UserMapper userMapper;

    public UserServiceImpl(
            UserRepository userRepository,
            UserProfileRepository userProfileRepository,
            UserMapper userMapper
    ) {
        this.userRepository = userRepository;
        this.userProfileRepository = userProfileRepository;
        this.userMapper = userMapper;
    }

    @Override
    @Transactional(readOnly = true)
    public UserResponse getCurrentUser(JwtPrincipal principal) {
        User user = userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User profile is not created yet."));

        return userMapper.toResponse(user);
    }

    @Override
    @Transactional
    public UserResponse updateCurrentUserProfile(JwtPrincipal principal, UpdateUserProfileRequest request) {
        User user = findCurrentUser(principal);
        UserProfile profile = userProfileRepository.findByUserId(user.getId())
                .orElseGet(() -> new UserProfile(user, null, null, null));

        profile.update(request.fullName(), request.email(), request.avatarUrl());
        UserProfile savedProfile = userProfileRepository.save(profile);

        return userMapper.toResponse(user, savedProfile);
    }

    private User findCurrentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User profile is not created yet."));
    }
}
