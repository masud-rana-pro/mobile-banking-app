package com.smartkash.agent.controller;

import com.smartkash.agent.dto.request.CreateAgentRequest;
import com.smartkash.agent.dto.response.AgentResponse;
import com.smartkash.agent.service.AgentService;
import com.smartkash.security.JwtPrincipal;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/agents")
public class AgentController {

    private final AgentService agentService;

    public AgentController(AgentService agentService) {
        this.agentService = agentService;
    }

    @PostMapping("/me")
    public AgentResponse createCurrentUserAgent(
            @AuthenticationPrincipal JwtPrincipal principal,
            @Valid @RequestBody CreateAgentRequest request
    ) {
        return agentService.createCurrentUserAgent(principal, request);
    }

    @GetMapping("/me")
    public AgentResponse getCurrentUserAgent(@AuthenticationPrincipal JwtPrincipal principal) {
        return agentService.getCurrentUserAgent(principal);
    }

    @GetMapping("/resolve")
    public AgentResponse resolveAgent(
            @AuthenticationPrincipal JwtPrincipal principal,
            @RequestParam String agentNumber
    ) {
        return agentService.resolveActiveAgent(principal, agentNumber);
    }
}
