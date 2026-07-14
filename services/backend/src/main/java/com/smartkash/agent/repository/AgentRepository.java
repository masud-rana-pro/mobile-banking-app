package com.smartkash.agent.repository;

import com.smartkash.agent.entity.Agent;
import com.smartkash.agent.enums.AgentStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AgentRepository extends JpaRepository<Agent, Long> {

    Optional<Agent> findByUser_Id(Long userId);

    Optional<Agent> findByAgentNumber(String agentNumber);

    boolean existsByUser_Id(Long userId);

    boolean existsByAgentNumber(String agentNumber);

    List<Agent> findByStatusOrderByCreatedAtDesc(AgentStatus status);
}
