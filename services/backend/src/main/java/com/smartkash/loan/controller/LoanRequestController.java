package com.smartkash.loan.controller;

import com.smartkash.loan.dto.request.CreateLoanRequest;
import com.smartkash.loan.dto.response.LoanRequestResponse;
import com.smartkash.loan.service.LoanRequestService;
import com.smartkash.security.JwtPrincipal;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/loans/requests")
public class LoanRequestController {

    private final LoanRequestService loanRequestService;

    public LoanRequestController(LoanRequestService loanRequestService) {
        this.loanRequestService = loanRequestService;
    }

    @PostMapping
    public ResponseEntity<LoanRequestResponse> createRequest(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody CreateLoanRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(loanRequestService.createCurrentUserRequest(principal, request));
    }

    @GetMapping
    public ResponseEntity<List<LoanRequestResponse>> currentUserRequests(
            @AuthenticationPrincipal JwtPrincipal principal
    ) {
        return ResponseEntity.ok(loanRequestService.getCurrentUserRequests(principal));
    }
}
