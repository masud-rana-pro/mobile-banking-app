package com.smartkash.wallet.controller;

import com.smartkash.security.JwtPrincipal;
import com.smartkash.wallet.dto.response.WalletResponse;
import com.smartkash.wallet.service.WalletService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/wallet")
public class WalletController {

    private final WalletService walletService;

    public WalletController(WalletService walletService) {
        this.walletService = walletService;
    }

    @GetMapping("/me")
    public ResponseEntity<WalletResponse> currentUserWallet(@AuthenticationPrincipal JwtPrincipal principal) {
        return ResponseEntity.ok(walletService.getCurrentUserWallet(principal));
    }
}
