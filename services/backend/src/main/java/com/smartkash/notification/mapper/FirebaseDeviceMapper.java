package com.smartkash.notification.mapper;

import com.smartkash.notification.dto.response.FirebaseDeviceResponse;
import com.smartkash.notification.entity.FirebaseDevice;
import org.springframework.stereotype.Component;

@Component
public class FirebaseDeviceMapper {

    public FirebaseDeviceResponse toResponse(FirebaseDevice device) {
        return new FirebaseDeviceResponse(
                device.getId(),
                device.getDeviceType(),
                device.isActive(),
                device.getCreatedAt(),
                device.getUpdatedAt()
        );
    }
}
