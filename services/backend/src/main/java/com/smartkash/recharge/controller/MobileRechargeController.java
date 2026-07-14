package com.smartkash.recharge.controller;

import com.smartkash.recharge.dto.request.CreateMobileRechargeRequest;
import com.smartkash.recharge.dto.response.MobileRechargeResponse;
import com.smartkash.recharge.service.MobileRechargeService;
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
@RequestMapping("/api/recharge")
public class MobileRechargeController {

    private final MobileRechargeService mobileRechargeService;

    public MobileRechargeController(MobileRechargeService mobileRechargeService) {
        this.mobileRechargeService = mobileRechargeService;
    }

    @PostMapping
    public ResponseEntity<MobileRechargeResponse> createRecharge(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody CreateMobileRechargeRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(mobileRechargeService.createRecharge(principal, request));
    }

    @GetMapping
    public ResponseEntity<List<MobileRechargeResponse>> currentUserRecharges(
            @AuthenticationPrincipal JwtPrincipal principal
    ) {
        return ResponseEntity.ok(mobileRechargeService.getCurrentUserRecharges(principal));
    }
}
