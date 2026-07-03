package com.smartkash.admin.controller;

import com.smartkash.addmoney.dto.response.AddMoneyRequestResponse;
import com.smartkash.admin.dto.response.AdminAuditLogResponse;
import com.smartkash.admin.service.AdminReadService;
import com.smartkash.loan.dto.response.LoanRequestResponse;
import com.smartkash.recharge.dto.response.MobileRechargeResponse;
import com.smartkash.transaction.dto.response.TransactionResponse;
import com.smartkash.user.dto.response.UserResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/admin")
public class AdminReadController {

    private final AdminReadService adminReadService;

    public AdminReadController(AdminReadService adminReadService) {
        this.adminReadService = adminReadService;
    }

    @GetMapping("/users")
    public ResponseEntity<List<UserResponse>> users() {
        return ResponseEntity.ok(adminReadService.getUsers());
    }

    @GetMapping("/transactions")
    public ResponseEntity<List<TransactionResponse>> transactions() {
        return ResponseEntity.ok(adminReadService.getTransactions());
    }

    @GetMapping("/add-money/requests")
    public ResponseEntity<List<AddMoneyRequestResponse>> addMoneyRequests() {
        return ResponseEntity.ok(adminReadService.getAddMoneyRequests());
    }

    @GetMapping("/loans/requests")
    public ResponseEntity<List<LoanRequestResponse>> loanRequests() {
        return ResponseEntity.ok(adminReadService.getLoanRequests());
    }

    @GetMapping("/recharges")
    public ResponseEntity<List<MobileRechargeResponse>> recharges() {
        return ResponseEntity.ok(adminReadService.getRecharges());
    }

    @GetMapping("/payments")
    public ResponseEntity<List<Object>> payments() {
        return ResponseEntity.ok(adminReadService.getPayments());
    }

    @GetMapping("/audit-logs")
    public ResponseEntity<List<AdminAuditLogResponse>> auditLogs() {
        return ResponseEntity.ok(adminReadService.getAuditLogs());
    }
}
