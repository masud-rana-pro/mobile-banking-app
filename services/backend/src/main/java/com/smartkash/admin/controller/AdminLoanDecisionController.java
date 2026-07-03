package com.smartkash.admin.controller;

import com.smartkash.admin.dto.request.AdminLoanDecisionRequest;
import com.smartkash.admin.service.AdminLoanDecisionService;
import com.smartkash.loan.dto.response.LoanRequestResponse;
import com.smartkash.security.JwtPrincipal;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/admin/loans/requests")
public class AdminLoanDecisionController {

    private final AdminLoanDecisionService adminLoanDecisionService;

    public AdminLoanDecisionController(AdminLoanDecisionService adminLoanDecisionService) {
        this.adminLoanDecisionService = adminLoanDecisionService;
    }

    @PostMapping("/{id}/approve")
    public ResponseEntity<LoanRequestResponse> approve(
            @AuthenticationPrincipal JwtPrincipal principal,
            @PathVariable Long id,
            @Valid @RequestBody AdminLoanDecisionRequest request
    ) {
        return ResponseEntity.ok(adminLoanDecisionService.approve(principal, id, request));
    }

    @PostMapping("/{id}/reject")
    public ResponseEntity<LoanRequestResponse> reject(
            @AuthenticationPrincipal JwtPrincipal principal,
            @PathVariable Long id,
            @Valid @RequestBody AdminLoanDecisionRequest request
    ) {
        return ResponseEntity.ok(adminLoanDecisionService.reject(principal, id, request));
    }
}
