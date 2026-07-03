package com.smartkash.savings.controller;

import com.smartkash.savings.dto.request.CreateSavingsGoalRequest;
import com.smartkash.savings.dto.response.SavingsGoalResponse;
import com.smartkash.savings.service.SavingsGoalService;
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
@RequestMapping("/api/savings/goals")
public class SavingsGoalController {

    private final SavingsGoalService savingsGoalService;

    public SavingsGoalController(SavingsGoalService savingsGoalService) {
        this.savingsGoalService = savingsGoalService;
    }

    @PostMapping
    public ResponseEntity<SavingsGoalResponse> createGoal(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody CreateSavingsGoalRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(savingsGoalService.createCurrentUserGoal(principal, request));
    }

    @GetMapping
    public ResponseEntity<List<SavingsGoalResponse>> currentUserGoals(
            @AuthenticationPrincipal JwtPrincipal principal
    ) {
        return ResponseEntity.ok(savingsGoalService.getCurrentUserGoals(principal));
    }
}
