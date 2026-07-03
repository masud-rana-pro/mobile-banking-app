package com.smartkash.idempotency.service.impl;

import com.smartkash.idempotency.entity.IdempotencyKey;
import com.smartkash.idempotency.enums.IdempotencyOperationType;
import com.smartkash.idempotency.repository.IdempotencyKeyRepository;
import com.smartkash.idempotency.service.IdempotencyKeyService;
import com.smartkash.user.entity.User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;

@Service
public class IdempotencyKeyServiceImpl implements IdempotencyKeyService {

    private final IdempotencyKeyRepository idempotencyKeyRepository;

    public IdempotencyKeyServiceImpl(IdempotencyKeyRepository idempotencyKeyRepository) {
        this.idempotencyKeyRepository = idempotencyKeyRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<IdempotencyKey> findForUser(Long userId, String idempotencyKey) {
        return idempotencyKeyRepository.findByUser_IdAndIdempotencyKey(userId, idempotencyKey);
    }

    @Override
    @Transactional
    public IdempotencyKey reserve(
            User user,
            String idempotencyKey,
            String requestHash,
            IdempotencyOperationType operationType,
            Instant expiresAt
    ) {
        return idempotencyKeyRepository.save(
                new IdempotencyKey(user, idempotencyKey, requestHash, operationType, expiresAt)
        );
    }

    @Override
    @Transactional
    public IdempotencyKey markCompleted(IdempotencyKey idempotencyKey, String responseBody) {
        idempotencyKey.markCompleted(responseBody);
        return idempotencyKeyRepository.save(idempotencyKey);
    }

    @Override
    @Transactional
    public IdempotencyKey markFailed(IdempotencyKey idempotencyKey, String responseBody) {
        idempotencyKey.markFailed(responseBody);
        return idempotencyKeyRepository.save(idempotencyKey);
    }
}
