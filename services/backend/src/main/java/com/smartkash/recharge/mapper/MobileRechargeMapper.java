package com.smartkash.recharge.mapper;

import com.smartkash.recharge.dto.response.MobileRechargeResponse;
import com.smartkash.recharge.entity.MobileRecharge;
import org.springframework.stereotype.Component;

@Component
public class MobileRechargeMapper {

    public MobileRechargeResponse toResponse(MobileRecharge recharge) {
        return new MobileRechargeResponse(
                recharge.getId(),
                recharge.getOperator(),
                recharge.getMobileNumber(),
                recharge.getAmount(),
                recharge.getStatus(),
                recharge.getTransactionReference(),
                recharge.getCreatedAt()
        );
    }
}
