package com.smartkash.merchant.repository;

import com.smartkash.merchant.entity.Merchant;
import com.smartkash.merchant.enums.MerchantStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MerchantRepository extends JpaRepository<Merchant, Long> {

    Optional<Merchant> findByUser_Id(Long userId);

    Optional<Merchant> findByMerchantNumber(String merchantNumber);

    boolean existsByUser_Id(Long userId);

    boolean existsByMerchantNumber(String merchantNumber);

    List<Merchant> findByStatusOrderByCreatedAtDesc(MerchantStatus status);
}
