package com.smartkash.agent.service;

import com.smartkash.agent.dto.request.CreateAgentRequest;
import com.smartkash.agent.dto.response.AgentResponse;
import com.smartkash.security.JwtPrincipal;

public interface AgentService {

    AgentResponse createCurrentUserAgent(JwtPrincipal principal, CreateAgentRequest request);

    AgentResponse getCurrentUserAgent(JwtPrincipal principal);
}
