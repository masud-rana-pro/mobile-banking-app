package com.smartkash.agent.entity;

import com.smartkash.agent.enums.AgentStatus;
import com.smartkash.user.entity.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "agents")
public class Agent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "business_name", nullable = false, length = 120)
    private String businessName;

    @Column(name = "agent_number", nullable = false, unique = true, length = 32)
    private String agentNumber;

    @Column(length = 160)
    private String location;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private AgentStatus status;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Agent() {
    }

    public Agent(User user, String businessName, String agentNumber, String location, AgentStatus status) {
        this.user = user;
        this.businessName = businessName;
        this.agentNumber = agentNumber;
        this.location = location;
        this.status = status;
    }

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public User getUser() {
        return user;
    }

    public String getBusinessName() {
        return businessName;
    }

    public String getAgentNumber() {
        return agentNumber;
    }

    public String getLocation() {
        return location;
    }

    public AgentStatus getStatus() {
        return status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
