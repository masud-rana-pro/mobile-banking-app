CREATE TABLE firebase_devices (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    fcm_token VARCHAR(500) NOT NULL,
    device_type VARCHAR(32) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT fk_firebase_devices_user_id FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT uk_firebase_devices_token UNIQUE (fcm_token),
    CONSTRAINT chk_firebase_devices_device_type CHECK (device_type IN ('ANDROID', 'IOS', 'WEB', 'WINDOWS', 'LINUX', 'MACOS', 'UNKNOWN'))
);

CREATE INDEX idx_firebase_devices_user_active ON firebase_devices (user_id, active);
