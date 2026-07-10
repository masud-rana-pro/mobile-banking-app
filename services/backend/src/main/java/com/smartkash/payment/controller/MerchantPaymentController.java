package com.smartkash.payment.controller;

import com.smartkash.payment.dto.request.MerchantPaymentRequest;
import com.smartkash.payment.dto.response.MerchantPaymentResponse;
import com.smartkash.payment.dto.response.MerchantPaymentTargetResponse;
import com.smartkash.payment.service.MerchantPaymentService;
import com.smartkash.security.JwtPrincipal;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/payments")
public class MerchantPaymentController {

    private final MerchantPaymentService merchantPaymentService;

    public MerchantPaymentController(MerchantPaymentService merchantPaymentService) {
        this.merchantPaymentService = merchantPaymentService;
    }

    @GetMapping("/merchant/resolve")
    public ResponseEntity<MerchantPaymentTargetResponse> resolveMerchant(
            @AuthenticationPrincipal JwtPrincipal principal,
            @RequestParam String merchantNumber
    ) {
        return ResponseEntity.ok(merchantPaymentService.resolveMerchant(principal, merchantNumber));
    }

    @PostMapping("/merchant")
    public ResponseEntity<MerchantPaymentResponse> payMerchant(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody MerchantPaymentRequest request
    ) {
        return ResponseEntity.ok(merchantPaymentService.payMerchant(principal, request));
    }
}
