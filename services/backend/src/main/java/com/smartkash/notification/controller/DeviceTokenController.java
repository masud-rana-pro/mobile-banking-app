package com.smartkash.notification.controller;

import com.smartkash.notification.dto.request.RegisterFcmTokenRequest;
import com.smartkash.notification.dto.response.FirebaseDeviceResponse;
import com.smartkash.notification.service.DeviceTokenService;
import com.smartkash.security.JwtPrincipal;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/devices")
public class DeviceTokenController {

    private final DeviceTokenService deviceTokenService;

    public DeviceTokenController(DeviceTokenService deviceTokenService) {
        this.deviceTokenService = deviceTokenService;
    }

    @PostMapping("/fcm-token")
    public ResponseEntity<FirebaseDeviceResponse> registerFcmToken(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody RegisterFcmTokenRequest request
    ) {
        return ResponseEntity.ok(deviceTokenService.registerCurrentUserToken(principal, request));
    }
}
