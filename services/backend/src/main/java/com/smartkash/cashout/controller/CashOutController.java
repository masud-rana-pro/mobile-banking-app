package com.smartkash.cashout.controller;

import com.smartkash.cashout.dto.request.CashOutRequest;
import com.smartkash.cashout.dto.response.CashOutResponse;
import com.smartkash.cashout.service.CashOutService;
import com.smartkash.security.JwtPrincipal;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/cash-out")
public class CashOutController {

    private final CashOutService cashOutService;

    public CashOutController(CashOutService cashOutService) {
        this.cashOutService = cashOutService;
    }

    @PostMapping
    public ResponseEntity<CashOutResponse> cashOut(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody CashOutRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(cashOutService.cashOut(principal, request));
    }
}
