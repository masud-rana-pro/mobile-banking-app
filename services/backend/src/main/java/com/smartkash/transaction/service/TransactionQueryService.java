package com.smartkash.transaction.service;

import com.smartkash.security.JwtPrincipal;
import com.smartkash.transaction.dto.response.TransactionResponse;
import com.smartkash.transaction.enums.TransactionStatus;
import com.smartkash.transaction.enums.TransactionType;

import java.time.Instant;
import java.util.List;

public interface TransactionQueryService {

    List<TransactionResponse> getCurrentUserTransactions(
            JwtPrincipal principal,
            TransactionType type,
            TransactionStatus status,
            Instant from,
            Instant to
    );

    TransactionResponse getCurrentUserTransaction(JwtPrincipal principal, Long transactionId);
}
