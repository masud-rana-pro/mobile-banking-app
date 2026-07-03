package com.smartkash.recharge.service.impl;

import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.recharge.dto.request.CreateMobileRechargeRequest;
import com.smartkash.recharge.dto.response.MobileRechargeResponse;
import com.smartkash.recharge.entity.MobileRecharge;
import com.smartkash.recharge.mapper.MobileRechargeMapper;
import com.smartkash.recharge.repository.MobileRechargeRepository;
import com.smartkash.recharge.service.MobileRechargeService;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.entity.User;
import com.smartkash.user.enums.UserStatus;
import com.smartkash.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class MobileRechargeServiceImpl implements MobileRechargeService {

    private final UserRepository userRepository;
    private final MobileRechargeRepository mobileRechargeRepository;
    private final MobileRechargeMapper mobileRechargeMapper;

    public MobileRechargeServiceImpl(
            UserRepository userRepository,
            MobileRechargeRepository mobileRechargeRepository,
            MobileRechargeMapper mobileRechargeMapper
    ) {
        this.userRepository = userRepository;
        this.mobileRechargeRepository = mobileRechargeRepository;
        this.mobileRechargeMapper = mobileRechargeMapper;
    }

    @Override
    @Transactional
    public MobileRechargeResponse createDemoRecharge(JwtPrincipal principal, CreateMobileRechargeRequest request) {
        User user = currentUser(principal);
        ensureActiveUser(user);
        MobileRecharge recharge = new MobileRecharge(
                user,
                request.operator(),
                request.mobileNumber(),
                request.amount()
        );
        return mobileRechargeMapper.toResponse(mobileRechargeRepository.save(recharge));
    }

    @Override
    @Transactional(readOnly = true)
    public List<MobileRechargeResponse> getCurrentUserRecharges(JwtPrincipal principal) {
        User user = currentUser(principal);
        return mobileRechargeRepository.findByUser_IdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(mobileRechargeMapper::toResponse)
                .toList();
    }

    private User currentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));
    }

    private void ensureActiveUser(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new IllegalArgumentException("Only active users can create mobile recharge records.");
        }
    }
}
