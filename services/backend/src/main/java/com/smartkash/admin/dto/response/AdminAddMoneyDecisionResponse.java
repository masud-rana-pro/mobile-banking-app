package com.smartkash.admin.dto.response;

import com.smartkash.addmoney.dto.response.AddMoneyRequestResponse;

import java.math.BigDecimal;

public record AdminAddMoneyDecisionResponse(
        AddMoneyRequestResponse request,
        String transactionReference,
        BigDecimal walletBalanceAfter
) {
}
