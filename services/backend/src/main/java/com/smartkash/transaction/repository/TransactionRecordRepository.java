package com.smartkash.transaction.repository;

import com.smartkash.transaction.entity.TransactionRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TransactionRecordRepository extends JpaRepository<TransactionRecord, Long> {

    Optional<TransactionRecord> findByTransactionReference(String transactionReference);

    List<TransactionRecord> findByUserIdOrderByCreatedAtDesc(Long userId);

    boolean existsByTransactionReference(String transactionReference);
}
