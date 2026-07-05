package com.smartkash.recharge.entity;

import com.smartkash.recharge.enums.MobileOperator;
import com.smartkash.recharge.enums.RechargeStatus;
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
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "mobile_recharges")
public class MobileRecharge {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private MobileOperator operator;

    @Column(name = "mobile_number", nullable = false, length = 20)
    private String mobileNumber;

    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private RechargeStatus status;

    @Column(name = "transaction_reference", length = 64)
    private String transactionReference;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected MobileRecharge() {
    }

    public MobileRecharge(User user, MobileOperator operator, String mobileNumber, BigDecimal amount) {
        this.user = user;
        this.operator = operator;
        this.mobileNumber = mobileNumber;
        this.amount = amount;
        this.status = RechargeStatus.SUCCESS;
    }

    @PrePersist
    void prePersist() {
        createdAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public User getUser() {
        return user;
    }

    public MobileOperator getOperator() {
        return operator;
    }

    public String getMobileNumber() {
        return mobileNumber;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public RechargeStatus getStatus() {
        return status;
    }

    public String getTransactionReference() {
        return transactionReference;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void attachTransactionReference(String transactionReference) {
        this.transactionReference = transactionReference;
    }
}
