package com.smartkash.firebase;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "smartkash.firebase")
public record FirebaseAdminProperties(
        String projectId,
        String clientEmail,
        String privateKey,
        String privateKeyId,
        String clientId
) {

    public boolean isConfigured() {
        return hasText(projectId) && hasText(clientEmail) && hasText(privateKey);
    }

    public String normalizedPrivateKey() {
        if (privateKey == null) {
            return "";
        }

        String normalized = privateKey.trim();
        if (normalized.length() >= 2 && normalized.startsWith("\"") && normalized.endsWith("\"")) {
            normalized = normalized.substring(1, normalized.length() - 1);
        }

        return normalized.replace("\\n", "\n").trim();
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
