package com.smartkash.addmoney.entity;

import com.smartkash.addmoney.enums.AddMoneySourceType;
import com.smartkash.addmoney.enums.AddMoneyStatus;
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
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "add_money_requests")
public class AddMoneyRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(name = "source_type", nullable = false, length = 40)
    private AddMoneySourceType sourceType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private AddMoneyStatus status;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by")
    private User approvedBy;

    @Column(name = "approved_at")
    private Instant approvedAt;

    @Column(length = 255)
    private String note;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected AddMoneyRequest() {
    }

    public AddMoneyRequest(User user, BigDecimal amount, AddMoneySourceType sourceType, String note) {
        this.user = user;
        this.amount = amount;
        this.sourceType = sourceType;
        this.status = AddMoneyStatus.PENDING;
        this.note = note;
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

    public BigDecimal getAmount() {
        return amount;
    }

    public AddMoneySourceType getSourceType() {
        return sourceType;
    }

    public AddMoneyStatus getStatus() {
        return status;
    }

    public User getApprovedBy() {
        return approvedBy;
    }

    public Instant getApprovedAt() {
        return approvedAt;
    }

    public String getNote() {
        return note;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void approve(User adminUser) {
        this.status = AddMoneyStatus.APPROVED;
        this.approvedBy = adminUser;
        this.approvedAt = Instant.now();
    }

    public void completeInstantly() {
        this.status = AddMoneyStatus.APPROVED;
        this.approvedBy = null;
        this.approvedAt = Instant.now();
    }

    public void reject(User adminUser) {
        this.status = AddMoneyStatus.REJECTED;
        this.approvedBy = adminUser;
        this.approvedAt = Instant.now();
    }
}
