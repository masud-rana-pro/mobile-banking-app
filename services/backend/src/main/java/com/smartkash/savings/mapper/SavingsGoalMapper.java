package com.smartkash.savings.mapper;

import com.smartkash.savings.dto.response.SavingsGoalResponse;
import com.smartkash.savings.entity.SavingsGoal;
import org.springframework.stereotype.Component;

@Component
public class SavingsGoalMapper {

    public SavingsGoalResponse toResponse(SavingsGoal goal) {
        return new SavingsGoalResponse(
                goal.getId(),
                goal.getName(),
                goal.getTargetAmount(),
                goal.getCurrentAmount(),
                goal.getTargetDate(),
                goal.getStatus(),
                goal.getCreatedAt(),
                goal.getUpdatedAt()
        );
    }
}
