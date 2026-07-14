package com.smartkash.agent.mapper;

import com.smartkash.agent.dto.response.AgentResponse;
import com.smartkash.agent.entity.Agent;
import org.springframework.stereotype.Component;

@Component
public class AgentMapper {

    public AgentResponse toResponse(Agent agent) {
        return new AgentResponse(
                agent.getId(),
                agent.getUser().getId(),
                agent.getBusinessName(),
                agent.getAgentNumber(),
                agent.getLocation(),
                agent.getStatus(),
                agent.getCreatedAt(),
                agent.getUpdatedAt()
        );
    }
}
