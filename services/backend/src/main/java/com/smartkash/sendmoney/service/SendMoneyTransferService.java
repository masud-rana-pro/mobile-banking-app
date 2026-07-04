package com.smartkash.sendmoney.service;

import com.smartkash.security.JwtPrincipal;
import com.smartkash.sendmoney.dto.request.SendMoneyRequest;
import com.smartkash.sendmoney.dto.response.SendMoneyTransferResponse;

public interface SendMoneyTransferService {

    SendMoneyTransferResponse sendMoney(JwtPrincipal principal, SendMoneyRequest request);
}
