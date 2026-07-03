package com.smartkash.admin.service;

import com.smartkash.admin.dto.request.AdminAddMoneyDecisionRequest;
import com.smartkash.admin.dto.response.AdminAddMoneyDecisionResponse;
import com.smartkash.security.JwtPrincipal;

public interface AdminAddMoneyDecisionService {

    AdminAddMoneyDecisionResponse approve(
            JwtPrincipal principal,
            Long requestId,
            AdminAddMoneyDecisionRequest request
    );

    AdminAddMoneyDecisionResponse reject(
            JwtPrincipal principal,
            Long requestId,
            AdminAddMoneyDecisionRequest request
    );
}
