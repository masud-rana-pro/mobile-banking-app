package com.smartkash.wallet.service;

import com.smartkash.security.JwtPrincipal;
import com.smartkash.wallet.dto.response.WalletResponse;

public interface WalletService {

    WalletResponse getCurrentUserWallet(JwtPrincipal principal);
}
