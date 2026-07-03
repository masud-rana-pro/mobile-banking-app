package com.smartkash.admin.service.impl;

import com.smartkash.addmoney.dto.response.AddMoneyRequestResponse;
import com.smartkash.addmoney.mapper.AddMoneyRequestMapper;
import com.smartkash.addmoney.repository.AddMoneyRequestRepository;
import com.smartkash.admin.dto.response.AdminAuditLogResponse;
import com.smartkash.admin.mapper.AdminAuditLogMapper;
import com.smartkash.admin.service.AdminReadService;
import com.smartkash.audit.repository.AdminAuditLogRepository;
import com.smartkash.loan.dto.response.LoanRequestResponse;
import com.smartkash.loan.mapper.LoanRequestMapper;
import com.smartkash.loan.repository.LoanRequestRepository;
import com.smartkash.recharge.dto.response.MobileRechargeResponse;
import com.smartkash.recharge.mapper.MobileRechargeMapper;
import com.smartkash.recharge.repository.MobileRechargeRepository;
import com.smartkash.transaction.dto.response.TransactionResponse;
import com.smartkash.transaction.mapper.TransactionRecordMapper;
import com.smartkash.transaction.repository.TransactionRecordRepository;
import com.smartkash.user.dto.response.UserResponse;
import com.smartkash.user.mapper.UserMapper;
import com.smartkash.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class AdminReadServiceImpl implements AdminReadService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;
    private final TransactionRecordRepository transactionRecordRepository;
    private final TransactionRecordMapper transactionRecordMapper;
    private final AddMoneyRequestRepository addMoneyRequestRepository;
    private final AddMoneyRequestMapper addMoneyRequestMapper;
    private final LoanRequestRepository loanRequestRepository;
    private final LoanRequestMapper loanRequestMapper;
    private final MobileRechargeRepository mobileRechargeRepository;
    private final MobileRechargeMapper mobileRechargeMapper;
    private final AdminAuditLogRepository adminAuditLogRepository;
    private final AdminAuditLogMapper adminAuditLogMapper;

    public AdminReadServiceImpl(
            UserRepository userRepository,
            UserMapper userMapper,
            TransactionRecordRepository transactionRecordRepository,
            TransactionRecordMapper transactionRecordMapper,
            AddMoneyRequestRepository addMoneyRequestRepository,
            AddMoneyRequestMapper addMoneyRequestMapper,
            LoanRequestRepository loanRequestRepository,
            LoanRequestMapper loanRequestMapper,
            MobileRechargeRepository mobileRechargeRepository,
            MobileRechargeMapper mobileRechargeMapper,
            AdminAuditLogRepository adminAuditLogRepository,
            AdminAuditLogMapper adminAuditLogMapper
    ) {
        this.userRepository = userRepository;
        this.userMapper = userMapper;
        this.transactionRecordRepository = transactionRecordRepository;
        this.transactionRecordMapper = transactionRecordMapper;
        this.addMoneyRequestRepository = addMoneyRequestRepository;
        this.addMoneyRequestMapper = addMoneyRequestMapper;
        this.loanRequestRepository = loanRequestRepository;
        this.loanRequestMapper = loanRequestMapper;
        this.mobileRechargeRepository = mobileRechargeRepository;
        this.mobileRechargeMapper = mobileRechargeMapper;
        this.adminAuditLogRepository = adminAuditLogRepository;
        this.adminAuditLogMapper = adminAuditLogMapper;
    }

    @Override
    @Transactional(readOnly = true)
    public List<UserResponse> getUsers() {
        return userRepository.findAll()
                .stream()
                .map(userMapper::toResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<TransactionResponse> getTransactions() {
        return transactionRecordRepository.findAllByOrderByCreatedAtDesc()
                .stream()
                .map(transactionRecordMapper::toResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<AddMoneyRequestResponse> getAddMoneyRequests() {
        return addMoneyRequestRepository.findAllByOrderByCreatedAtDesc()
                .stream()
                .map(addMoneyRequestMapper::toResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<LoanRequestResponse> getLoanRequests() {
        return loanRequestRepository.findAllByOrderByCreatedAtDesc()
                .stream()
                .map(loanRequestMapper::toResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<MobileRechargeResponse> getRecharges() {
        return mobileRechargeRepository.findAllByOrderByCreatedAtDesc()
                .stream()
                .map(mobileRechargeMapper::toResponse)
                .toList();
    }

    @Override
    public List<Object> getPayments() {
        return List.of();
    }

    @Override
    @Transactional(readOnly = true)
    public List<AdminAuditLogResponse> getAuditLogs() {
        return adminAuditLogRepository.findAllByOrderByCreatedAtDesc()
                .stream()
                .map(adminAuditLogMapper::toResponse)
                .toList();
    }
}
