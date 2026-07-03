package com.smartkash.merchant.mapper;

import com.smartkash.merchant.dto.response.MerchantResponse;
import com.smartkash.merchant.entity.Merchant;
import org.springframework.stereotype.Component;

@Component
public class MerchantMapper {

    public MerchantResponse toResponse(Merchant merchant) {
        return new MerchantResponse(
                merchant.getId(),
                merchant.getUser().getId(),
                merchant.getBusinessName(),
                merchant.getMerchantNumber(),
                merchant.getBusinessType(),
                merchant.getStatus(),
                merchant.getCreatedAt(),
                merchant.getUpdatedAt()
        );
    }
}
