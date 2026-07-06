package com.smartkash.notification.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "smartkash.fcm")
public record FcmProperties(boolean enabled) {
}
