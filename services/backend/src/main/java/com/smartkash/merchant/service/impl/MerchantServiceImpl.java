package com.smartkash.merchant.service.impl;

import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.merchant.dto.request.CreateMerchantRequest;
import com.smartkash.merchant.dto.response.MerchantResponse;
import com.smartkash.merchant.entity.Merchant;
import com.smartkash.merchant.enums.MerchantStatus;
import com.smartkash.merchant.mapper.MerchantMapper;
import com.smartkash.merchant.repository.MerchantRepository;
import com.smartkash.merchant.service.MerchantService;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.entity.User;
import com.smartkash.user.enums.UserStatus;
import com.smartkash.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MerchantServiceImpl implements MerchantService {

    private final UserRepository userRepository;
    private final MerchantRepository merchantRepository;
    private final MerchantMapper merchantMapper;

    public MerchantServiceImpl(
            UserRepository userRepository,
            MerchantRepository merchantRepository,
            MerchantMapper merchantMapper
    ) {
        this.userRepository = userRepository;
        this.merchantRepository = merchantRepository;
        this.merchantMapper = merchantMapper;
    }

    @Override
    @Transactional
    public MerchantResponse createCurrentUserMerchant(JwtPrincipal principal, CreateMerchantRequest request) {
        User user = currentUser(principal);
        ensureActiveUser(user);
        ensureMerchantDoesNotExist(user.getId());
        ensureMerchantNumberIsUnique(request.merchantNumber());

        user.makeMerchant();
        userRepository.save(user);

        Merchant merchant = new Merchant(
                user,
                request.businessName(),
                request.merchantNumber(),
                request.businessType(),
                MerchantStatus.ACTIVE
        );

        return merchantMapper.toResponse(merchantRepository.save(merchant));
    }

    @Override
    @Transactional(readOnly = true)
    public MerchantResponse getCurrentUserMerchant(JwtPrincipal principal) {
        User user = currentUser(principal);
        Merchant merchant = merchantRepository.findByUser_Id(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Merchant profile is not created yet."));

        return merchantMapper.toResponse(merchant);
    }

    private User currentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));
    }

    private void ensureActiveUser(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new IllegalArgumentException("Only active users can create merchant profiles.");
        }
    }

    private void ensureMerchantDoesNotExist(Long userId) {
        if (merchantRepository.existsByUser_Id(userId)) {
            throw new IllegalArgumentException("Merchant profile already exists for this user.");
        }
    }

    private void ensureMerchantNumberIsUnique(String merchantNumber) {
        if (merchantRepository.existsByMerchantNumber(merchantNumber)) {
            throw new IllegalArgumentException("Merchant number is already used.");
        }
    }
}
