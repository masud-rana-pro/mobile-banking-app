package com.smartkash.loan.repository;

import com.smartkash.loan.entity.LoanRequest;
import com.smartkash.loan.enums.LoanStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LoanRequestRepository extends JpaRepository<LoanRequest, Long> {

    List<LoanRequest> findByUser_IdOrderByCreatedAtDesc(Long userId);

    List<LoanRequest> findByStatusOrderByCreatedAtDesc(LoanStatus status);

    List<LoanRequest> findAllByOrderByCreatedAtDesc();
}
