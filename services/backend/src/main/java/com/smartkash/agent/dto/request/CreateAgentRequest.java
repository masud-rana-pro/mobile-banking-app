package com.smartkash.agent.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record CreateAgentRequest(
        @NotBlank(message = "Agent business name is required.")
        @Size(max = 120, message = "Agent business name must be 120 characters or less.")
        String businessName,

        @NotBlank(message = "Agent number is required.")
        @Pattern(regexp = "^(\\+8801|8801|01|1)[0-9]{9}$", message = "Agent number must be a valid Bangladesh mobile number.")
        String agentNumber,

        @Size(max = 160, message = "Location must be 160 characters or less.")
        String location
) {
}
