package com.smartkash.transaction.mapper;

import com.smartkash.transaction.dto.response.TransactionResponse;
import com.smartkash.transaction.entity.TransactionRecord;
import com.smartkash.user.entity.User;
import org.springframework.stereotype.Component;

@Component
public class TransactionRecordMapper {

    public TransactionResponse toResponse(TransactionRecord transaction) {
        User counterparty = transaction.getCounterpartyUser();
        return new TransactionResponse(
                transaction.getId(),
                transaction.getTransactionReference(),
                transaction.getType(),
                transaction.getStatus(),
                transaction.getAmount(),
                counterparty == null ? null : counterparty.getId(),
                counterparty == null ? null : counterparty.getMobileNumber(),
                transaction.getDescription(),
                transaction.getCreatedAt()
        );
    }
}
