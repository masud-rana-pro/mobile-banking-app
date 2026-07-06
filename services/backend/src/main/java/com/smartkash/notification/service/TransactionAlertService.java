package com.smartkash.notification.service;

import com.smartkash.notification.enums.NotificationType;
import com.smartkash.user.entity.User;

import java.util.Map;

public interface TransactionAlertService {

    void sendTransactionAlert(User user, NotificationType type, String title, String body, Map<String, String> data);
}
