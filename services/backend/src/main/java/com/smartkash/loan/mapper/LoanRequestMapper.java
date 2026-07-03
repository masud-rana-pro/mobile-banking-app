package com.smartkash.loan.mapper;

import com.smartkash.loan.dto.response.LoanRequestResponse;
import com.smartkash.loan.entity.LoanRequest;
import org.springframework.stereotype.Component;

@Component
public class LoanRequestMapper {

    public LoanRequestResponse toResponse(LoanRequest request) {
        return new LoanRequestResponse(
                request.getId(),
                request.getAmount(),
                request.getPurpose(),
                request.getStatus(),
                request.getReviewedAt(),
                request.getCreatedAt(),
                request.getUpdatedAt()
        );
    }
}
