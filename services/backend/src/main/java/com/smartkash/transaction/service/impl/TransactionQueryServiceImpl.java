package com.smartkash.transaction.service.impl;

import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.transaction.dto.response.TransactionResponse;
import com.smartkash.transaction.enums.TransactionStatus;
import com.smartkash.transaction.enums.TransactionType;
import com.smartkash.transaction.mapper.TransactionRecordMapper;
import com.smartkash.transaction.repository.TransactionRecordRepository;
import com.smartkash.transaction.service.TransactionQueryService;
import com.smartkash.user.entity.User;
import com.smartkash.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
public class TransactionQueryServiceImpl implements TransactionQueryService {

    private final UserRepository userRepository;
    private final TransactionRecordRepository transactionRecordRepository;
    private final TransactionRecordMapper transactionRecordMapper;

    public TransactionQueryServiceImpl(
            UserRepository userRepository,
            TransactionRecordRepository transactionRecordRepository,
            TransactionRecordMapper transactionRecordMapper
    ) {
        this.userRepository = userRepository;
        this.transactionRecordRepository = transactionRecordRepository;
        this.transactionRecordMapper = transactionRecordMapper;
    }

    @Override
    @Transactional(readOnly = true)
    public List<TransactionResponse> getCurrentUserTransactions(
            JwtPrincipal principal,
            TransactionType type,
            TransactionStatus status,
            Instant from,
            Instant to
    ) {
        User user = currentUser(principal);
        return transactionRecordRepository.findCurrentUserTransactions(user.getId(), type, status, from, to)
                .stream()
                .map(transactionRecordMapper::toResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public TransactionResponse getCurrentUserTransaction(JwtPrincipal principal, Long transactionId) {
        User user = currentUser(principal);
        return transactionRecordRepository.findByIdAndUserId(transactionId, user.getId())
                .map(transactionRecordMapper::toResponse)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction was not found for the current user."));
    }

    private User currentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));
    }
}
