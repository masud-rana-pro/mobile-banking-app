package com.smartkash.admin.service;

import com.smartkash.admin.dto.request.AdminLoanDecisionRequest;
import com.smartkash.loan.dto.response.LoanRequestResponse;
import com.smartkash.security.JwtPrincipal;

public interface AdminLoanDecisionService {

    LoanRequestResponse approve(JwtPrincipal principal, Long requestId, AdminLoanDecisionRequest request);

    LoanRequestResponse reject(JwtPrincipal principal, Long requestId, AdminLoanDecisionRequest request);
}
