package com.smartkash.idempotency.service;

import com.smartkash.idempotency.entity.IdempotencyKey;
import com.smartkash.idempotency.enums.IdempotencyOperationType;
import com.smartkash.user.entity.User;

import java.time.Instant;
import java.util.Optional;

public interface IdempotencyKeyService {

    Optional<IdempotencyKey> findForUser(Long userId, String idempotencyKey);

    IdempotencyKey reserve(
            User user,
            String idempotencyKey,
            String requestHash,
            IdempotencyOperationType operationType,
            Instant expiresAt
    );

    IdempotencyKey markCompleted(IdempotencyKey idempotencyKey, String responseBody);

    IdempotencyKey markFailed(IdempotencyKey idempotencyKey, String responseBody);
}
