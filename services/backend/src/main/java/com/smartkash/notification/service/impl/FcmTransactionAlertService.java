package com.smartkash.notification.service.impl;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.smartkash.firebase.FirebaseAdminInitializer;
import com.smartkash.notification.config.FcmProperties;
import com.smartkash.notification.entity.FirebaseDevice;
import com.smartkash.notification.enums.NotificationType;
import com.smartkash.notification.repository.FirebaseDeviceRepository;
import com.smartkash.notification.service.TransactionAlertService;
import com.smartkash.user.entity.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Optional;

@Service
public class FcmTransactionAlertService implements TransactionAlertService {

    private static final Logger log = LoggerFactory.getLogger(FcmTransactionAlertService.class);

    private final FcmProperties fcmProperties;
    private final FirebaseAdminInitializer firebaseAdminInitializer;
    private final FirebaseDeviceRepository firebaseDeviceRepository;

    public FcmTransactionAlertService(
            FcmProperties fcmProperties,
            FirebaseAdminInitializer firebaseAdminInitializer,
            FirebaseDeviceRepository firebaseDeviceRepository
    ) {
        this.fcmProperties = fcmProperties;
        this.firebaseAdminInitializer = firebaseAdminInitializer;
        this.firebaseDeviceRepository = firebaseDeviceRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public void sendTransactionAlert(
            User user,
            NotificationType type,
            String title,
            String body,
            Map<String, String> data
    ) {
        Optional<FirebaseApp> firebaseApp = firebaseAdminInitializer.firebaseApp();
        if (!fcmProperties.enabled() || firebaseApp.isEmpty()) {
            log.info("Skipping FCM alert because FCM is disabled or Firebase Admin is not configured. userId={}, type={}",
                    user.getId(),
                    type
            );
            return;
        }

        for (FirebaseDevice device : firebaseDeviceRepository.findByUser_IdAndActiveTrue(user.getId())) {
            sendToDevice(firebaseApp.get(), device, type, title, body, data);
        }
    }

    private void sendToDevice(
            FirebaseApp firebaseApp,
            FirebaseDevice device,
            NotificationType type,
            String title,
            String body,
            Map<String, String> data
    ) {
        Message message = Message.builder()
                .setToken(device.getFcmToken())
                .setNotification(Notification.builder()
                        .setTitle(title)
                        .setBody(body)
                        .build())
                .putAllData(data == null ? Map.of() : data)
                .putData("type", type.name())
                .build();

        try {
            FirebaseMessaging.getInstance(firebaseApp).send(message);
        } catch (FirebaseMessagingException exception) {
            log.warn("Failed to send FCM alert to deviceId={}.", device.getId(), exception);
        }
    }
}
