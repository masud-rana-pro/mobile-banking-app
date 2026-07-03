package com.smartkash.savings.service;

import com.smartkash.savings.dto.request.CreateSavingsGoalRequest;
import com.smartkash.savings.dto.response.SavingsGoalResponse;
import com.smartkash.security.JwtPrincipal;

import java.util.List;

public interface SavingsGoalService {

    SavingsGoalResponse createCurrentUserGoal(JwtPrincipal principal, CreateSavingsGoalRequest request);

    List<SavingsGoalResponse> getCurrentUserGoals(JwtPrincipal principal);
}
