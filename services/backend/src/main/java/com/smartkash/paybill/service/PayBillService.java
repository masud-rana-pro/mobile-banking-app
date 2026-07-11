package com.smartkash.paybill.service;

import com.smartkash.paybill.dto.request.PayBillRequest;
import com.smartkash.paybill.dto.response.PayBillResponse;
import com.smartkash.security.JwtPrincipal;

public interface PayBillService {

    PayBillResponse payBill(JwtPrincipal principal, PayBillRequest request);
}
