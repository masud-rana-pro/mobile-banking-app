package com.smartkash.sendmoney.controller;

import com.smartkash.security.JwtPrincipal;
import com.smartkash.sendmoney.dto.request.ResolveSendMoneyReceiverRequest;
import com.smartkash.sendmoney.dto.request.SendMoneyRequest;
import com.smartkash.sendmoney.dto.response.SendMoneyReceiverResponse;
import com.smartkash.sendmoney.dto.response.SendMoneyTransferResponse;
import com.smartkash.sendmoney.service.SendMoneyReceiverService;
import com.smartkash.sendmoney.service.SendMoneyTransferService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/send-money")
public class SendMoneyReceiverController {

    private final SendMoneyReceiverService sendMoneyReceiverService;
    private final SendMoneyTransferService sendMoneyTransferService;

    public SendMoneyReceiverController(
            SendMoneyReceiverService sendMoneyReceiverService,
            SendMoneyTransferService sendMoneyTransferService
    ) {
        this.sendMoneyReceiverService = sendMoneyReceiverService;
        this.sendMoneyTransferService = sendMoneyTransferService;
    }

    @PostMapping("/resolve-receiver")
    public ResponseEntity<SendMoneyReceiverResponse> resolveReceiver(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody ResolveSendMoneyReceiverRequest request
    ) {
        return ResponseEntity.ok(sendMoneyReceiverService.resolveReceiver(principal, request));
    }

    @PostMapping
    public ResponseEntity<SendMoneyTransferResponse> sendMoney(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody SendMoneyRequest request
    ) {
        return ResponseEntity.ok(sendMoneyTransferService.sendMoney(principal, request));
    }
}
