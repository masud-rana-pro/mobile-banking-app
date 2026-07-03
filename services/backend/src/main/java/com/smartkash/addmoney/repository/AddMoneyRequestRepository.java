package com.smartkash.addmoney.repository;

import com.smartkash.addmoney.entity.AddMoneyRequest;
import com.smartkash.addmoney.enums.AddMoneyStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface AddMoneyRequestRepository extends JpaRepository<AddMoneyRequest, Long> {

    List<AddMoneyRequest> findByUser_IdOrderByCreatedAtDesc(Long userId);

    List<AddMoneyRequest> findByStatusOrderByCreatedAtDesc(AddMoneyStatus status);

    List<AddMoneyRequest> findAllByOrderByCreatedAtDesc();

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from AddMoneyRequest r where r.id = :id")
    Optional<AddMoneyRequest> findByIdForUpdate(@Param("id") Long id);
}
