package com.smartkash.user.service;

import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.dto.response.UserResponse;

public interface UserService {

    UserResponse getCurrentUser(JwtPrincipal principal);
}
