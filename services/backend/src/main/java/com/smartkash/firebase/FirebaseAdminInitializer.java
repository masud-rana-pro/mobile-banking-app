package com.smartkash.firebase;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Optional;

@Component
public class FirebaseAdminInitializer {

    private static final Logger log = LoggerFactory.getLogger(FirebaseAdminInitializer.class);

    private final FirebaseAdminProperties properties;
    private FirebaseApp firebaseApp;

    public FirebaseAdminInitializer(FirebaseAdminProperties properties) {
        this.properties = properties;
    }

    @PostConstruct
    void initialize() {
        if (!properties.isConfigured()) {
            log.info("Firebase Admin SDK is not initialized because environment credentials are missing.");
            return;
        }

        if (!FirebaseApp.getApps().isEmpty()) {
            firebaseApp = FirebaseApp.getApps().get(0);
            return;
        }

        try {
            GoogleCredentials credentials = GoogleCredentials.fromStream(
                    new ByteArrayInputStream(serviceAccountJson().getBytes(StandardCharsets.UTF_8))
            );

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(credentials)
                    .setProjectId(properties.projectId())
                    .build();

            firebaseApp = FirebaseApp.initializeApp(options);
            log.info("Firebase Admin SDK initialized for project {}.", properties.projectId());
        } catch (IOException exception) {
            throw new IllegalStateException("Failed to initialize Firebase Admin SDK.", exception);
        }
    }

    public Optional<FirebaseApp> firebaseApp() {
        return Optional.ofNullable(firebaseApp);
    }

    private String serviceAccountJson() {
        return """
                {
                  "type": "service_account",
                  "project_id": "%s",
                  "private_key": "%s",
                  "client_email": "%s",
                  "token_uri": "https://oauth2.googleapis.com/token"
                }
                """.formatted(
                escapeJson(properties.projectId()),
                escapeJson(properties.normalizedPrivateKey()),
                escapeJson(properties.clientEmail())
        );
    }

    private String escapeJson(String value) {
        return value
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\r", "\\r")
                .replace("\n", "\\n");
    }
}
