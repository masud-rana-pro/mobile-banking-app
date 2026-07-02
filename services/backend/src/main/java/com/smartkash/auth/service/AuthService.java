package com.smartkash.auth.service;

import com.smartkash.auth.dto.request.FirebaseLoginRequest;
import com.smartkash.auth.dto.response.AuthTokenResponse;

public interface AuthService {

    AuthTokenResponse loginWithFirebase(FirebaseLoginRequest request);
}
