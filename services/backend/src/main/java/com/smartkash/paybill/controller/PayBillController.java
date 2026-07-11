package com.smartkash.paybill.controller;

import com.smartkash.paybill.dto.request.PayBillRequest;
import com.smartkash.paybill.dto.response.PayBillResponse;
import com.smartkash.paybill.service.PayBillService;
import com.smartkash.security.JwtPrincipal;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/pay-bill")
public class PayBillController {

    private final PayBillService payBillService;

    public PayBillController(PayBillService payBillService) {
        this.payBillService = payBillService;
    }

    @PostMapping
    public ResponseEntity<PayBillResponse> payBill(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody PayBillRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(payBillService.payBill(principal, request));
    }
}
