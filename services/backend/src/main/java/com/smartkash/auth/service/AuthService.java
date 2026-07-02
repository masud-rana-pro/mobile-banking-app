package com.smartkash.auth.service;

import com.smartkash.auth.dto.request.FirebaseLoginRequest;
import com.smartkash.auth.dto.request.SetPinRequest;
import com.smartkash.auth.dto.request.VerifyPinRequest;
import com.smartkash.auth.dto.response.AuthTokenResponse;
import com.smartkash.auth.dto.response.PinSetupResponse;
import com.smartkash.auth.dto.response.PinVerificationResponse;
import com.smartkash.security.JwtPrincipal;

public interface AuthService {

    AuthTokenResponse loginWithFirebase(FirebaseLoginRequest request);

    PinSetupResponse setPin(JwtPrincipal principal, SetPinRequest request);

    PinVerificationResponse verifyPin(JwtPrincipal principal, VerifyPinRequest request);
}
