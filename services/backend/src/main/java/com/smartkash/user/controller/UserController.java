package com.smartkash.user.controller;

import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.dto.request.UpdateUserProfileRequest;
import com.smartkash.user.dto.response.UserResponse;
import com.smartkash.user.service.UserService;
import jakarta.validation.Valid;
import org.springframework.core.io.Resource;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public ResponseEntity<UserResponse> currentUser(@AuthenticationPrincipal JwtPrincipal principal) {
        return ResponseEntity.ok(userService.getCurrentUser(principal));
    }

    @GetMapping("/resolve")
    public ResponseEntity<UserResponse> resolveUserByMobileNumber(
            @AuthenticationPrincipal JwtPrincipal principal,
            @RequestParam String mobileNumber
    ) {
        return ResponseEntity.ok(userService.resolveUserByMobileNumber(principal, mobileNumber));
    }

    @PutMapping("/me/profile")
    public ResponseEntity<UserResponse> updateCurrentUserProfile(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody UpdateUserProfileRequest request
    ) {
        return ResponseEntity.ok(userService.updateCurrentUserProfile(principal, request));
    }

    @PostMapping("/me/profile-image")
    public ResponseEntity<UserResponse> uploadCurrentUserProfileImage(
            @AuthenticationPrincipal JwtPrincipal principal,
            @RequestParam("image") MultipartFile image
    ) {
        return ResponseEntity.ok(userService.uploadCurrentUserProfileImage(principal, image));
    }

    @GetMapping("/profile-images/{imageId}")
    public ResponseEntity<Resource> readProfileImage(@PathVariable String imageId) {
        return userService.readProfileImage(imageId);
    }
}
