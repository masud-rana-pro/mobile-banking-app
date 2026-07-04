package com.smartkash.savings.repository;

import com.smartkash.savings.entity.SavingsGoal;
import com.smartkash.savings.enums.SavingsGoalStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SavingsGoalRepository extends JpaRepository<SavingsGoal, Long> {

    List<SavingsGoal> findByUser_IdOrderByCreatedAtDesc(Long userId);

    List<SavingsGoal> findByUser_IdAndStatusOrderByCreatedAtDesc(Long userId, SavingsGoalStatus status);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select g from SavingsGoal g where g.id = :goalId and g.user.id = :userId")
    Optional<SavingsGoal> findByIdAndUserIdForUpdate(@Param("goalId") Long goalId, @Param("userId") Long userId);
}
