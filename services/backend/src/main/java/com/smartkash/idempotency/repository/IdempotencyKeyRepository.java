package com.smartkash.idempotency.repository;

import com.smartkash.idempotency.entity.IdempotencyKey;
import com.smartkash.idempotency.enums.IdempotencyOperationType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface IdempotencyKeyRepository extends JpaRepository<IdempotencyKey, Long> {

    Optional<IdempotencyKey> findByUser_IdAndIdempotencyKey(Long userId, String idempotencyKey);

    boolean existsByUser_IdAndIdempotencyKey(Long userId, String idempotencyKey);

    List<IdempotencyKey> findByUser_IdAndOperationTypeOrderByCreatedAtDesc(
            Long userId,
            IdempotencyOperationType operationType
    );

    List<IdempotencyKey> findByExpiresAtBefore(Instant expiresAt);
}
