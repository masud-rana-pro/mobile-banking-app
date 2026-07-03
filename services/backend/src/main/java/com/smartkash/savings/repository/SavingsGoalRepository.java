package com.smartkash.savings.repository;

import com.smartkash.savings.entity.SavingsGoal;
import com.smartkash.savings.enums.SavingsGoalStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SavingsGoalRepository extends JpaRepository<SavingsGoal, Long> {

    List<SavingsGoal> findByUser_IdOrderByCreatedAtDesc(Long userId);

    List<SavingsGoal> findByUser_IdAndStatusOrderByCreatedAtDesc(Long userId, SavingsGoalStatus status);
}
