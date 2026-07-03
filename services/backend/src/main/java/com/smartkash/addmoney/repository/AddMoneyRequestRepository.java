package com.smartkash.addmoney.repository;

import com.smartkash.addmoney.entity.AddMoneyRequest;
import com.smartkash.addmoney.enums.AddMoneyStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AddMoneyRequestRepository extends JpaRepository<AddMoneyRequest, Long> {

    List<AddMoneyRequest> findByUser_IdOrderByCreatedAtDesc(Long userId);

    List<AddMoneyRequest> findByStatusOrderByCreatedAtDesc(AddMoneyStatus status);

    List<AddMoneyRequest> findAllByOrderByCreatedAtDesc();
}
