package com.smartkash.auth.dto.response;

import java.time.Instant;

public record PinSetupResponse(
        boolean pinSet,
        Instant pinUpdatedAt
) {
}
