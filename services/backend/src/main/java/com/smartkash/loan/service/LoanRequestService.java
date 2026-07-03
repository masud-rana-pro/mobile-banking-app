package com.smartkash.loan.service;

import com.smartkash.loan.dto.request.CreateLoanRequest;
import com.smartkash.loan.dto.response.LoanRequestResponse;
import com.smartkash.security.JwtPrincipal;

import java.util.List;

public interface LoanRequestService {

    LoanRequestResponse createCurrentUserRequest(JwtPrincipal principal, CreateLoanRequest request);

    List<LoanRequestResponse> getCurrentUserRequests(JwtPrincipal principal);
}
