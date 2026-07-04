package com.smartkash.sendmoney.service;

import com.smartkash.security.JwtPrincipal;
import com.smartkash.sendmoney.dto.request.ResolveSendMoneyReceiverRequest;
import com.smartkash.sendmoney.dto.response.SendMoneyReceiverResponse;

public interface SendMoneyReceiverService {

    SendMoneyReceiverResponse resolveReceiver(JwtPrincipal principal, ResolveSendMoneyReceiverRequest request);
}
