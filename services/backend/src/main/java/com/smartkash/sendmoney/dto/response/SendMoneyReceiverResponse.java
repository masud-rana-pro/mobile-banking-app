package com.smartkash.sendmoney.dto.response;

import com.smartkash.user.enums.UserRole;
import com.smartkash.user.enums.UserStatus;
import com.smartkash.wallet.enums.WalletStatus;

public record SendMoneyReceiverResponse(
        Long userId,
        String mobileNumber,
        String displayName,
        String avatarUrl,
        UserRole role,
        UserStatus userStatus,
        WalletStatus walletStatus
) {
}
