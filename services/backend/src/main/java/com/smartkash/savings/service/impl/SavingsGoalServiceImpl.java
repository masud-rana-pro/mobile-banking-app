package com.smartkash.savings.service.impl;

import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.savings.dto.request.CreateSavingsGoalRequest;
import com.smartkash.savings.dto.response.SavingsGoalResponse;
import com.smartkash.savings.entity.SavingsGoal;
import com.smartkash.savings.mapper.SavingsGoalMapper;
import com.smartkash.savings.repository.SavingsGoalRepository;
import com.smartkash.savings.service.SavingsGoalService;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.entity.User;
import com.smartkash.user.enums.UserStatus;
import com.smartkash.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class SavingsGoalServiceImpl implements SavingsGoalService {

    private final UserRepository userRepository;
    private final SavingsGoalRepository savingsGoalRepository;
    private final SavingsGoalMapper savingsGoalMapper;

    public SavingsGoalServiceImpl(
            UserRepository userRepository,
            SavingsGoalRepository savingsGoalRepository,
            SavingsGoalMapper savingsGoalMapper
    ) {
        this.userRepository = userRepository;
        this.savingsGoalRepository = savingsGoalRepository;
        this.savingsGoalMapper = savingsGoalMapper;
    }

    @Override
    @Transactional
    public SavingsGoalResponse createCurrentUserGoal(JwtPrincipal principal, CreateSavingsGoalRequest request) {
        User user = currentUser(principal);
        ensureActiveUser(user);
        SavingsGoal goal = new SavingsGoal(
                user,
                request.name(),
                request.targetAmount(),
                request.targetDate()
        );
        return savingsGoalMapper.toResponse(savingsGoalRepository.save(goal));
    }

    @Override
    @Transactional(readOnly = true)
    public List<SavingsGoalResponse> getCurrentUserGoals(JwtPrincipal principal) {
        User user = currentUser(principal);
        return savingsGoalRepository.findByUser_IdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(savingsGoalMapper::toResponse)
                .toList();
    }

    private User currentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));
    }

    private void ensureActiveUser(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new IllegalArgumentException("Only active users can create savings goals.");
        }
    }
}
