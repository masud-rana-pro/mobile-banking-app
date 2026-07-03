package com.smartkash.transaction.repository;

import com.smartkash.transaction.entity.TransactionRecord;
import com.smartkash.transaction.enums.TransactionStatus;
import com.smartkash.transaction.enums.TransactionType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface TransactionRecordRepository extends JpaRepository<TransactionRecord, Long> {

    Optional<TransactionRecord> findByTransactionReference(String transactionReference);

    List<TransactionRecord> findByUserIdOrderByCreatedAtDesc(Long userId);

    Optional<TransactionRecord> findByIdAndUserId(Long id, Long userId);

    @Query("""
            select t
            from TransactionRecord t
            where t.user.id = :userId
              and (:type is null or t.type = :type)
              and (:status is null or t.status = :status)
              and (:fromTime is null or t.createdAt >= :fromTime)
              and (:toTime is null or t.createdAt <= :toTime)
            order by t.createdAt desc
            """)
    List<TransactionRecord> findCurrentUserTransactions(
            @Param("userId") Long userId,
            @Param("type") TransactionType type,
            @Param("status") TransactionStatus status,
            @Param("fromTime") Instant from,
            @Param("toTime") Instant to
    );

    boolean existsByTransactionReference(String transactionReference);
}
