package com.smartkash.addmoney.controller;

import com.smartkash.addmoney.dto.request.CreateAddMoneyRequest;
import com.smartkash.addmoney.dto.response.AddMoneyRequestResponse;
import com.smartkash.addmoney.service.AddMoneyRequestService;
import com.smartkash.security.JwtPrincipal;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/add-money/requests")
public class AddMoneyRequestController {

    private final AddMoneyRequestService addMoneyRequestService;

    public AddMoneyRequestController(AddMoneyRequestService addMoneyRequestService) {
        this.addMoneyRequestService = addMoneyRequestService;
    }

    @PostMapping
    public ResponseEntity<AddMoneyRequestResponse> createRequest(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody CreateAddMoneyRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(addMoneyRequestService.createCurrentUserRequest(principal, request));
    }

    @GetMapping
    public ResponseEntity<List<AddMoneyRequestResponse>> currentUserRequests(
            @AuthenticationPrincipal JwtPrincipal principal
    ) {
        return ResponseEntity.ok(addMoneyRequestService.getCurrentUserRequests(principal));
    }
}
