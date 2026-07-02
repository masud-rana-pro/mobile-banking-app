package com.smartkash.user.controller;

import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.dto.response.UserResponse;
import com.smartkash.user.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
}
