package com.smartkash.recharge.mapper;

import com.smartkash.recharge.dto.response.MobileRechargeResponse;
import com.smartkash.recharge.entity.MobileRecharge;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

@Component
public class MobileRechargeMapper {

    public MobileRechargeResponse toResponse(MobileRecharge recharge) {
        return toResponse(recharge, null);
    }

    public MobileRechargeResponse toResponse(MobileRecharge recharge, BigDecimal balanceAfter) {
        return new MobileRechargeResponse(
                recharge.getId(),
                recharge.getOperator(),
                recharge.getMobileNumber(),
                recharge.getAmount(),
                recharge.getStatus(),
                recharge.getTransactionReference(),
                balanceAfter,
                recharge.getCreatedAt()
        );
    }
}
