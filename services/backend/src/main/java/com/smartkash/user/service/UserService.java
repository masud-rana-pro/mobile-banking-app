package com.smartkash.user.service;

import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.dto.request.UpdateUserProfileRequest;
import com.smartkash.user.dto.response.UserResponse;
import org.springframework.core.io.Resource;
import org.springframework.http.ResponseEntity;
import org.springframework.web.multipart.MultipartFile;

public interface UserService {

    UserResponse getCurrentUser(JwtPrincipal principal);

    UserResponse updateCurrentUserProfile(JwtPrincipal principal, UpdateUserProfileRequest request);

    UserResponse uploadCurrentUserProfileImage(JwtPrincipal principal, MultipartFile image);

    ResponseEntity<Resource> readProfileImage(String imageId);
}
