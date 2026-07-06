package com.smartkash.notification.repository;

import com.smartkash.notification.entity.FirebaseDevice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FirebaseDeviceRepository extends JpaRepository<FirebaseDevice, Long> {

    Optional<FirebaseDevice> findByFcmToken(String fcmToken);

    List<FirebaseDevice> findByUser_IdAndActiveTrue(Long userId);
}
