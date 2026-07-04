package com.smartkash.payment.service;

import com.smartkash.payment.dto.request.MerchantPaymentRequest;
import com.smartkash.payment.dto.response.MerchantPaymentResponse;
import com.smartkash.security.JwtPrincipal;

public interface MerchantPaymentService {

    MerchantPaymentResponse payMerchant(JwtPrincipal principal, MerchantPaymentRequest request);
}
