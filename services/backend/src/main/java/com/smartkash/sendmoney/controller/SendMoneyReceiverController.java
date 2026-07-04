package com.smartkash.sendmoney.controller;

import com.smartkash.security.JwtPrincipal;
import com.smartkash.sendmoney.dto.request.ResolveSendMoneyReceiverRequest;
import com.smartkash.sendmoney.dto.response.SendMoneyReceiverResponse;
import com.smartkash.sendmoney.service.SendMoneyReceiverService;
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

    public SendMoneyReceiverController(SendMoneyReceiverService sendMoneyReceiverService) {
        this.sendMoneyReceiverService = sendMoneyReceiverService;
    }

    @PostMapping("/resolve-receiver")
    public ResponseEntity<SendMoneyReceiverResponse> resolveReceiver(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody ResolveSendMoneyReceiverRequest request
    ) {
        return ResponseEntity.ok(sendMoneyReceiverService.resolveReceiver(principal, request));
    }
}
