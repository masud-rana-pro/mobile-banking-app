package com.smartkash.admin.service.impl;

import com.smartkash.admin.dto.request.AdminLoanDecisionRequest;
import com.smartkash.admin.service.AdminLoanDecisionService;
import com.smartkash.audit.enums.AuditAction;
import com.smartkash.audit.enums.AuditTargetType;
import com.smartkash.audit.service.AdminAuditLogService;
import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.loan.dto.response.LoanRequestResponse;
import com.smartkash.loan.entity.LoanRequest;
import com.smartkash.loan.enums.LoanStatus;
import com.smartkash.loan.mapper.LoanRequestMapper;
import com.smartkash.loan.repository.LoanRequestRepository;
import com.smartkash.notification.enums.NotificationType;
import com.smartkash.notification.service.TransactionAlertService;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.entity.User;
import com.smartkash.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

@Service
public class AdminLoanDecisionServiceImpl implements AdminLoanDecisionService {

    private final UserRepository userRepository;
    private final LoanRequestRepository loanRequestRepository;
    private final LoanRequestMapper loanRequestMapper;
    private final AdminAuditLogService adminAuditLogService;
    private final TransactionAlertService transactionAlertService;

    public AdminLoanDecisionServiceImpl(
            UserRepository userRepository,
            LoanRequestRepository loanRequestRepository,
            LoanRequestMapper loanRequestMapper,
            AdminAuditLogService adminAuditLogService,
            TransactionAlertService transactionAlertService
    ) {
        this.userRepository = userRepository;
        this.loanRequestRepository = loanRequestRepository;
        this.loanRequestMapper = loanRequestMapper;
        this.adminAuditLogService = adminAuditLogService;
        this.transactionAlertService = transactionAlertService;
    }

    @Override
    @Transactional
    public LoanRequestResponse approve(JwtPrincipal principal, Long requestId, AdminLoanDecisionRequest request) {
        User adminUser = currentAdmin(principal);
        LoanRequest loanRequest = pendingLoanRequest(requestId);
        loanRequest.approve(adminUser);
        LoanRequest savedRequest = loanRequestRepository.save(loanRequest);
        adminAuditLogService.recordAdminAction(
                adminUser,
                AuditAction.LOAN_APPROVE,
                AuditTargetType.LOAN_REQUEST,
                String.valueOf(savedRequest.getId()),
                "Approved Loan request. note=" + nullToEmpty(request.note())
        );
        transactionAlertService.sendTransactionAlert(
                savedRequest.getUser(),
                NotificationType.LOAN,
                "Loan request approved",
                "Your loan request of BDT " + savedRequest.getAmount() + " was approved.",
                Map.of("loanRequestId", String.valueOf(savedRequest.getId()), "status", LoanStatus.APPROVED.name())
        );
        return loanRequestMapper.toResponse(savedRequest);
    }

    @Override
    @Transactional
    public LoanRequestResponse reject(JwtPrincipal principal, Long requestId, AdminLoanDecisionRequest request) {
        User adminUser = currentAdmin(principal);
        LoanRequest loanRequest = pendingLoanRequest(requestId);
        loanRequest.reject(adminUser);
        LoanRequest savedRequest = loanRequestRepository.save(loanRequest);
        adminAuditLogService.recordAdminAction(
                adminUser,
                AuditAction.LOAN_REJECT,
                AuditTargetType.LOAN_REQUEST,
                String.valueOf(savedRequest.getId()),
                "Rejected Loan request. note=" + nullToEmpty(request.note())
        );
        transactionAlertService.sendTransactionAlert(
                savedRequest.getUser(),
                NotificationType.LOAN,
                "Loan request rejected",
                "Your loan request of BDT " + savedRequest.getAmount() + " was rejected.",
                Map.of("loanRequestId", String.valueOf(savedRequest.getId()), "status", LoanStatus.REJECTED.name())
        );
        return loanRequestMapper.toResponse(savedRequest);
    }

    private User currentAdmin(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("Admin user account was not found."));
    }

    private LoanRequest pendingLoanRequest(Long requestId) {
        LoanRequest loanRequest = loanRequestRepository.findByIdForUpdate(requestId)
                .orElseThrow(() -> new ResourceNotFoundException("Loan request was not found."));
        if (loanRequest.getStatus() != LoanStatus.PENDING) {
            throw new IllegalArgumentException("Only pending Loan requests can be approved or rejected.");
        }
        return loanRequest;
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}
