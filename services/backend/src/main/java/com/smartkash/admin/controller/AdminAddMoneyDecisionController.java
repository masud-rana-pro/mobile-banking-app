package com.smartkash.admin.controller;

import com.smartkash.admin.dto.request.AdminAddMoneyDecisionRequest;
import com.smartkash.admin.dto.response.AdminAddMoneyDecisionResponse;
import com.smartkash.admin.service.AdminAddMoneyDecisionService;
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
@RequestMapping("/admin/add-money/requests")
public class AdminAddMoneyDecisionController {

    private final AdminAddMoneyDecisionService adminAddMoneyDecisionService;

    public AdminAddMoneyDecisionController(AdminAddMoneyDecisionService adminAddMoneyDecisionService) {
        this.adminAddMoneyDecisionService = adminAddMoneyDecisionService;
    }

    @PostMapping("/{id}/approve")
    public ResponseEntity<AdminAddMoneyDecisionResponse> approve(
            @AuthenticationPrincipal JwtPrincipal principal,
            @PathVariable Long id,
            @Valid @RequestBody AdminAddMoneyDecisionRequest request
    ) {
        return ResponseEntity.ok(adminAddMoneyDecisionService.approve(principal, id, request));
    }

    @PostMapping("/{id}/reject")
    public ResponseEntity<AdminAddMoneyDecisionResponse> reject(
            @AuthenticationPrincipal JwtPrincipal principal,
            @PathVariable Long id,
            @Valid @RequestBody AdminAddMoneyDecisionRequest request
    ) {
        return ResponseEntity.ok(adminAddMoneyDecisionService.reject(principal, id, request));
    }
}
