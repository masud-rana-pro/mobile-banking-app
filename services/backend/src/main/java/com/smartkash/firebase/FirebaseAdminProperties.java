package com.smartkash.firebase;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "smartkash.firebase")
public record FirebaseAdminProperties(
        String projectId,
        String clientEmail,
        String privateKey
) {

    public boolean isConfigured() {
        return hasText(projectId) && hasText(clientEmail) && hasText(privateKey);
    }

    public String normalizedPrivateKey() {
        return privateKey == null ? "" : privateKey.replace("\\n", "\n");
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
