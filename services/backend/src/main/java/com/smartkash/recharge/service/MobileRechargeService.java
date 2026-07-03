package com.smartkash.recharge.service;

import com.smartkash.recharge.dto.request.CreateMobileRechargeRequest;
import com.smartkash.recharge.dto.response.MobileRechargeResponse;
import com.smartkash.security.JwtPrincipal;

import java.util.List;

public interface MobileRechargeService {

    MobileRechargeResponse createDemoRecharge(JwtPrincipal principal, CreateMobileRechargeRequest request);

    List<MobileRechargeResponse> getCurrentUserRecharges(JwtPrincipal principal);
}
