package com.smartkash.user.service.impl;

import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.dto.response.UserResponse;
import com.smartkash.user.entity.User;
import com.smartkash.user.mapper.UserMapper;
import com.smartkash.user.repository.UserRepository;
import com.smartkash.user.service.UserService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;

    public UserServiceImpl(UserRepository userRepository, UserMapper userMapper) {
        this.userRepository = userRepository;
        this.userMapper = userMapper;
    }

    @Override
    @Transactional(readOnly = true)
    public UserResponse getCurrentUser(JwtPrincipal principal) {
        User user = userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User profile is not created yet."));

        return userMapper.toResponse(user);
    }
}
