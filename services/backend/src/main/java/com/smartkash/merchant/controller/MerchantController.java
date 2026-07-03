package com.smartkash.merchant.controller;

import com.smartkash.merchant.dto.request.CreateMerchantRequest;
import com.smartkash.merchant.dto.response.MerchantResponse;
import com.smartkash.merchant.service.MerchantService;
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

@RestController
@RequestMapping("/api/merchants")
public class MerchantController {

    private final MerchantService merchantService;

    public MerchantController(MerchantService merchantService) {
        this.merchantService = merchantService;
    }

    @PostMapping("/me")
    public ResponseEntity<MerchantResponse> createCurrentUserMerchant(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody CreateMerchantRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(merchantService.createCurrentUserMerchant(principal, request));
    }

    @GetMapping("/me")
    public ResponseEntity<MerchantResponse> currentUserMerchant(
            @AuthenticationPrincipal JwtPrincipal principal
    ) {
        return ResponseEntity.ok(merchantService.getCurrentUserMerchant(principal));
    }
}
