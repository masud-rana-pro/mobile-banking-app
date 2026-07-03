package com.smartkash.wallet.service;

import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.entity.User;
import com.smartkash.wallet.dto.response.WalletResponse;
import com.smartkash.wallet.entity.Wallet;

public interface WalletService {

    WalletResponse getCurrentUserWallet(JwtPrincipal principal);

    Wallet ensureWalletForUser(User user);
}
