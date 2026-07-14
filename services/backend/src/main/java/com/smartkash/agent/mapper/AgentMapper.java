package com.smartkash.agent.mapper;

import com.smartkash.agent.dto.response.AgentResponse;
import com.smartkash.agent.entity.Agent;
import com.smartkash.user.entity.User;
import com.smartkash.user.entity.UserProfile;
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
                avatarUrl(agent.getUser()),
                agent.getStatus(),
                agent.getCreatedAt(),
                agent.getUpdatedAt()
        );
    }

    private String avatarUrl(User user) {
        UserProfile profile = user.getProfile();
        if (profile == null) {
            return null;
        }
        if (profile.getAvatarImageId() != null && !profile.getAvatarImageId().isBlank()) {
            return "/api/users/profile-images/" + profile.getAvatarImageId();
        }
        return profile.getAvatarUrl();
    }
}
