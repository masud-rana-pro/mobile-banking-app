package com.smartkash.merchant.entity;

import com.smartkash.merchant.enums.MerchantStatus;
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
@Table(name = "merchants")
public class Merchant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "business_name", nullable = false, length = 120)
    private String businessName;

    @Column(name = "merchant_number", nullable = false, unique = true, length = 32)
    private String merchantNumber;

    @Column(name = "business_type", nullable = false, length = 80)
    private String businessType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private MerchantStatus status;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Merchant() {
    }

    public Merchant(
            User user,
            String businessName,
            String merchantNumber,
            String businessType,
            MerchantStatus status
    ) {
        this.user = user;
        this.businessName = businessName;
        this.merchantNumber = merchantNumber;
        this.businessType = businessType;
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

    public String getMerchantNumber() {
        return merchantNumber;
    }

    public String getBusinessType() {
        return businessType;
    }

    public MerchantStatus getStatus() {
        return status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
