package com.smartkash.loan.service.impl;

import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.loan.dto.request.CreateLoanRequest;
import com.smartkash.loan.dto.response.LoanRequestResponse;
import com.smartkash.loan.entity.LoanRequest;
import com.smartkash.loan.mapper.LoanRequestMapper;
import com.smartkash.loan.repository.LoanRequestRepository;
import com.smartkash.loan.service.LoanRequestService;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.entity.User;
import com.smartkash.user.enums.UserStatus;
import com.smartkash.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class LoanRequestServiceImpl implements LoanRequestService {

    private final UserRepository userRepository;
    private final LoanRequestRepository loanRequestRepository;
    private final LoanRequestMapper loanRequestMapper;

    public LoanRequestServiceImpl(
            UserRepository userRepository,
            LoanRequestRepository loanRequestRepository,
            LoanRequestMapper loanRequestMapper
    ) {
        this.userRepository = userRepository;
        this.loanRequestRepository = loanRequestRepository;
        this.loanRequestMapper = loanRequestMapper;
    }

    @Override
    @Transactional
    public LoanRequestResponse createCurrentUserRequest(JwtPrincipal principal, CreateLoanRequest request) {
        User user = currentUser(principal);
        ensureActiveUser(user);
        LoanRequest loanRequest = new LoanRequest(user, request.amount(), request.purpose());
        return loanRequestMapper.toResponse(loanRequestRepository.save(loanRequest));
    }

    @Override
    @Transactional(readOnly = true)
    public List<LoanRequestResponse> getCurrentUserRequests(JwtPrincipal principal) {
        User user = currentUser(principal);
        return loanRequestRepository.findByUser_IdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(loanRequestMapper::toResponse)
                .toList();
    }

    private User currentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));
    }

    private void ensureActiveUser(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new IllegalArgumentException("Only active users can create Loan requests.");
        }
    }
}
