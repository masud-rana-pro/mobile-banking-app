package com.smartkash.agent.service.impl;

import com.smartkash.agent.dto.request.CreateAgentRequest;
import com.smartkash.agent.dto.response.AgentResponse;
import com.smartkash.agent.entity.Agent;
import com.smartkash.agent.enums.AgentStatus;
import com.smartkash.agent.mapper.AgentMapper;
import com.smartkash.agent.repository.AgentRepository;
import com.smartkash.agent.service.AgentService;
import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.entity.User;
import com.smartkash.user.enums.UserRole;
import com.smartkash.user.enums.UserStatus;
import com.smartkash.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AgentServiceImpl implements AgentService {

    private final UserRepository userRepository;
    private final AgentRepository agentRepository;
    private final AgentMapper agentMapper;

    public AgentServiceImpl(UserRepository userRepository, AgentRepository agentRepository, AgentMapper agentMapper) {
        this.userRepository = userRepository;
        this.agentRepository = agentRepository;
        this.agentMapper = agentMapper;
    }

    @Override
    @Transactional
    public AgentResponse createCurrentUserAgent(JwtPrincipal principal, CreateAgentRequest request) {
        User user = currentUser(principal);
        ensureActiveUser(user);
        ensureUserIsNotMerchant(user);
        ensureAgentDoesNotExist(user.getId());

        String agentNumber = normalizeAgentNumber(request.agentNumber());
        ensureAgentNumberIsUnique(agentNumber);

        user.makeAgent();
        userRepository.save(user);

        Agent agent = new Agent(
                user,
                request.businessName().trim(),
                agentNumber,
                blankToNull(request.location()),
                AgentStatus.ACTIVE
        );

        return agentMapper.toResponse(agentRepository.save(agent));
    }

    @Override
    @Transactional(readOnly = true)
    public AgentResponse getCurrentUserAgent(JwtPrincipal principal) {
        User user = currentUser(principal);
        Agent agent = agentRepository.findByUser_Id(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Agent profile is not created yet."));

        return agentMapper.toResponse(agent);
    }

    private User currentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));
    }

    private void ensureActiveUser(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new IllegalArgumentException("Only active users can create agent profiles.");
        }
    }

    private void ensureUserIsNotMerchant(User user) {
        if (user.getRole() == UserRole.MERCHANT) {
            throw new IllegalArgumentException("Merchant users cannot open an agent account. Use a separate mobile number.");
        }
    }

    private void ensureAgentDoesNotExist(Long userId) {
        if (agentRepository.existsByUser_Id(userId)) {
            throw new IllegalArgumentException("Agent profile already exists for this user.");
        }
    }

    private void ensureAgentNumberIsUnique(String agentNumber) {
        if (agentRepository.existsByAgentNumber(agentNumber)) {
            throw new IllegalArgumentException("Agent number is already used.");
        }
    }

    private String normalizeAgentNumber(String agentNumber) {
        String normalized = agentNumber.trim().replace(" ", "").replace("-", "");
        if (normalized.startsWith("+880") && normalized.matches("^\\+8801[0-9]{9}$")) {
            return normalized;
        }
        if (normalized.startsWith("880") && normalized.matches("^8801[0-9]{9}$")) {
            return "+" + normalized;
        }
        if (normalized.startsWith("01") && normalized.matches("^01[0-9]{9}$")) {
            return "+88" + normalized;
        }
        if (normalized.startsWith("1") && normalized.matches("^1[0-9]{9}$")) {
            return "+880" + normalized;
        }
        throw new IllegalArgumentException("Agent number must be a valid Bangladesh mobile number.");
    }

    private String blankToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }
}
