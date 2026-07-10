package com.smartkash.payment.service;

import com.smartkash.payment.dto.request.MerchantPaymentRequest;
import com.smartkash.payment.dto.response.MerchantPaymentResponse;
import com.smartkash.payment.dto.response.MerchantPaymentTargetResponse;
import com.smartkash.security.JwtPrincipal;

public interface MerchantPaymentService {

    MerchantPaymentTargetResponse resolveMerchant(JwtPrincipal principal, String merchantNumber);

    MerchantPaymentResponse payMerchant(JwtPrincipal principal, MerchantPaymentRequest request);
}
