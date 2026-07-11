package com.smartkash.cashout.service;

import com.smartkash.cashout.dto.request.CashOutRequest;
import com.smartkash.cashout.dto.response.CashOutResponse;
import com.smartkash.security.JwtPrincipal;

public interface CashOutService {

    CashOutResponse cashOut(JwtPrincipal principal, CashOutRequest request);
}
