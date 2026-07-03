package com.smartkash.addmoney.mapper;

import com.smartkash.addmoney.dto.response.AddMoneyRequestResponse;
import com.smartkash.addmoney.entity.AddMoneyRequest;
import org.springframework.stereotype.Component;

@Component
public class AddMoneyRequestMapper {

    public AddMoneyRequestResponse toResponse(AddMoneyRequest request) {
        return new AddMoneyRequestResponse(
                request.getId(),
                request.getAmount(),
                request.getSourceType(),
                request.getStatus(),
                request.getNote(),
                request.getApprovedAt(),
                request.getCreatedAt(),
                request.getUpdatedAt()
        );
    }
}
