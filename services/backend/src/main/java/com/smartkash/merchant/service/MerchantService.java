package com.smartkash.merchant.service;

import com.smartkash.merchant.dto.request.CreateMerchantRequest;
import com.smartkash.merchant.dto.response.MerchantResponse;
import com.smartkash.security.JwtPrincipal;

public interface MerchantService {

    MerchantResponse createCurrentUserMerchant(JwtPrincipal principal, CreateMerchantRequest request);

    MerchantResponse getCurrentUserMerchant(JwtPrincipal principal);
}
