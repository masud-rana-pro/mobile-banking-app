package com.smartkash.wallet.service.impl;

import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.entity.User;
import com.smartkash.user.repository.UserRepository;
import com.smartkash.wallet.dto.response.WalletResponse;
import com.smartkash.wallet.entity.Wallet;
import com.smartkash.wallet.enums.WalletStatus;
import com.smartkash.wallet.mapper.WalletMapper;
import com.smartkash.wallet.repository.WalletRepository;
import com.smartkash.wallet.service.WalletService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

@Service
public class WalletServiceImpl implements WalletService {

    private static final String DEFAULT_CURRENCY = "BDT";

    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final WalletMapper walletMapper;

    public WalletServiceImpl(
            UserRepository userRepository,
            WalletRepository walletRepository,
            WalletMapper walletMapper
    ) {
        this.userRepository = userRepository;
        this.walletRepository = walletRepository;
        this.walletMapper = walletMapper;
    }

    @Override
    @Transactional(readOnly = true)
    public WalletResponse getCurrentUserWallet(JwtPrincipal principal) {
        User user = userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));

        Wallet wallet = walletRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Wallet is not created yet."));

        return walletMapper.toResponse(wallet);
    }

    @Override
    @Transactional
    public Wallet ensureWalletForUser(User user) {
        return walletRepository.findByUserId(user.getId())
                .orElseGet(() -> walletRepository.save(
                        new Wallet(user, BigDecimal.ZERO, DEFAULT_CURRENCY, WalletStatus.ACTIVE)
                ));
    }
}
