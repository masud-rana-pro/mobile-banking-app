package com.smartkash.recharge.repository;

import com.smartkash.recharge.entity.MobileRecharge;
import com.smartkash.recharge.enums.RechargeStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MobileRechargeRepository extends JpaRepository<MobileRecharge, Long> {

    List<MobileRecharge> findByUser_IdOrderByCreatedAtDesc(Long userId);

    List<MobileRecharge> findByStatusOrderByCreatedAtDesc(RechargeStatus status);

    List<MobileRecharge> findAllByOrderByCreatedAtDesc();
}
