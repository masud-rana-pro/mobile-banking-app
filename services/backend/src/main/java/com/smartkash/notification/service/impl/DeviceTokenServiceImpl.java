package com.smartkash.notification.service.impl;

import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.notification.dto.request.RegisterFcmTokenRequest;
import com.smartkash.notification.dto.response.FirebaseDeviceResponse;
import com.smartkash.notification.entity.FirebaseDevice;
import com.smartkash.notification.mapper.FirebaseDeviceMapper;
import com.smartkash.notification.repository.FirebaseDeviceRepository;
import com.smartkash.notification.service.DeviceTokenService;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.entity.User;
import com.smartkash.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DeviceTokenServiceImpl implements DeviceTokenService {

    private final UserRepository userRepository;
    private final FirebaseDeviceRepository firebaseDeviceRepository;
    private final FirebaseDeviceMapper firebaseDeviceMapper;

    public DeviceTokenServiceImpl(
            UserRepository userRepository,
            FirebaseDeviceRepository firebaseDeviceRepository,
            FirebaseDeviceMapper firebaseDeviceMapper
    ) {
        this.userRepository = userRepository;
        this.firebaseDeviceRepository = firebaseDeviceRepository;
        this.firebaseDeviceMapper = firebaseDeviceMapper;
    }

    @Override
    @Transactional
    public FirebaseDeviceResponse registerCurrentUserToken(JwtPrincipal principal, RegisterFcmTokenRequest request) {
        User user = userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));

        FirebaseDevice device = firebaseDeviceRepository.findByFcmToken(request.fcmToken().trim())
                .map(existingDevice -> refresh(existingDevice, user, request))
                .orElseGet(() -> new FirebaseDevice(user, request.fcmToken().trim(), request.deviceType()));

        return firebaseDeviceMapper.toResponse(firebaseDeviceRepository.save(device));
    }

    private FirebaseDevice refresh(FirebaseDevice device, User user, RegisterFcmTokenRequest request) {
        device.refresh(user, request.deviceType());
        return device;
    }
}
