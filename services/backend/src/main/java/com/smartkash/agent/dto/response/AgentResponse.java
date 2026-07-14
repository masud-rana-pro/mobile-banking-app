package com.smartkash.agent.dto.response;

import com.smartkash.agent.enums.AgentStatus;

import java.time.Instant;

public record AgentResponse(
        Long id,
        Long userId,
        String businessName,
        String agentNumber,
        String location,
        AgentStatus status,
        Instant createdAt,
        Instant updatedAt
) {
}
