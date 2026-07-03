package com.smartkash.addmoney.service;

import com.smartkash.addmoney.dto.request.CreateAddMoneyRequest;
import com.smartkash.addmoney.dto.response.AddMoneyRequestResponse;
import com.smartkash.security.JwtPrincipal;

import java.util.List;

public interface AddMoneyRequestService {

    AddMoneyRequestResponse createCurrentUserRequest(JwtPrincipal principal, CreateAddMoneyRequest request);

    List<AddMoneyRequestResponse> getCurrentUserRequests(JwtPrincipal principal);
}
