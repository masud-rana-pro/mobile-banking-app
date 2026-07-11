package com.smartkash.loan.service.impl;

import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.loan.dto.request.CreateLoanRequest;
import com.smartkash.loan.dto.response.LoanRequestResponse;
import com.smartkash.loan.entity.LoanRequest;
import com.smartkash.loan.mapper.LoanRequestMapper;
import com.smartkash.loan.repository.LoanRequestRepository;
import com.smartkash.loan.service.LoanRequestService;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.transaction.entity.TransactionRecord;
import com.smartkash.transaction.enums.TransactionStatus;
import com.smartkash.transaction.enums.TransactionType;
import com.smartkash.transaction.repository.TransactionRecordRepository;
import com.smartkash.user.entity.User;
import com.smartkash.user.enums.UserStatus;
import com.smartkash.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class LoanRequestServiceImpl implements LoanRequestService {

    private final UserRepository userRepository;
    private final LoanRequestRepository loanRequestRepository;
    private final LoanRequestMapper loanRequestMapper;
    private final TransactionRecordRepository transactionRecordRepository;

    public LoanRequestServiceImpl(
            UserRepository userRepository,
            LoanRequestRepository loanRequestRepository,
            LoanRequestMapper loanRequestMapper,
            TransactionRecordRepository transactionRecordRepository
    ) {
        this.userRepository = userRepository;
        this.loanRequestRepository = loanRequestRepository;
        this.loanRequestMapper = loanRequestMapper;
        this.transactionRecordRepository = transactionRecordRepository;
    }

    @Override
    @Transactional
    public LoanRequestResponse createCurrentUserRequest(JwtPrincipal principal, CreateLoanRequest request) {
        User user = currentUser(principal);
        ensureActiveUser(user);
        LoanRequest loanRequest = new LoanRequest(user, request.amount(), request.purpose());
        LoanRequest savedRequest = loanRequestRepository.save(loanRequest);
        transactionRecordRepository.save(new TransactionRecord(
                uniqueTransactionReference(),
                user,
                TransactionType.LOAN_REQUEST,
                TransactionStatus.PENDING,
                request.amount(),
                null,
                "Loan request submitted: " + request.purpose()
        ));
        return loanRequestMapper.toResponse(savedRequest);
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

    private String uniqueTransactionReference() {
        String reference;
        do {
            reference = "LN-" + UUID.randomUUID().toString().replace("-", "").substring(0, 24).toUpperCase();
        } while (transactionRecordRepository.existsByTransactionReference(reference));
        return reference;
    }
}
