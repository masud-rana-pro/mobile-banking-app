package com.smartkash.wallet.dto.response;

import com.smartkash.wallet.enums.WalletStatus;

import java.math.BigDecimal;
import java.time.Instant;

public record WalletResponse(
        Long id,
        Long userId,
        BigDecimal balance,
        String currency,
        WalletStatus status,
        Instant createdAt,
        Instant updatedAt
) {
}
