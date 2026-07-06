package com.smartkash.notification.service;

import com.smartkash.notification.dto.request.RegisterFcmTokenRequest;
import com.smartkash.notification.dto.response.FirebaseDeviceResponse;
import com.smartkash.security.JwtPrincipal;

public interface DeviceTokenService {

    FirebaseDeviceResponse registerCurrentUserToken(JwtPrincipal principal, RegisterFcmTokenRequest request);
}
