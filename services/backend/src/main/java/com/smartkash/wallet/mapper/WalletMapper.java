package com.smartkash.wallet.mapper;

import com.smartkash.wallet.dto.response.WalletResponse;
import com.smartkash.wallet.entity.Wallet;
import org.springframework.stereotype.Component;

@Component
public class WalletMapper {

    public WalletResponse toResponse(Wallet wallet) {
        return new WalletResponse(
                wallet.getId(),
                wallet.getUser().getId(),
                wallet.getBalance(),
                wallet.getCurrency(),
                wallet.getStatus(),
                wallet.getCreatedAt(),
                wallet.getUpdatedAt()
        );
    }
}
