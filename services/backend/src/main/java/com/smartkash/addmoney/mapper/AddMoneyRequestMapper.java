package com.smartkash.addmoney.mapper;

import com.smartkash.addmoney.dto.response.AddMoneyRequestResponse;
import com.smartkash.addmoney.entity.AddMoneyRequest;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

@Component
public class AddMoneyRequestMapper {

    public AddMoneyRequestResponse toResponse(AddMoneyRequest request) {
        return toResponse(request, null, null);
    }

    public AddMoneyRequestResponse toResponse(
            AddMoneyRequest request,
            String transactionReference,
            BigDecimal balanceAfter
    ) {
        return new AddMoneyRequestResponse(
                request.getId(),
                request.getAmount(),
                request.getSourceType(),
                request.getStatus(),
                request.getNote(),
                transactionReference,
                balanceAfter,
                request.getApprovedAt(),
                request.getCreatedAt(),
                request.getUpdatedAt()
        );
    }
}
