package com.smartkash.user.entity;

import com.smartkash.user.enums.UserRole;
import com.smartkash.user.enums.UserStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "firebase_uid", nullable = false, unique = true, length = 128)
    private String firebaseUid;

    @Column(name = "mobile_number", nullable = false, unique = true, length = 32)
    private String mobileNumber;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private UserRole role;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private UserStatus status;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "pin_hash", length = 255)
    private String pinHash;

    @Column(name = "pin_set", nullable = false)
    private boolean pinSet;

    @Column(name = "pin_updated_at")
    private Instant pinUpdatedAt;

    @OneToOne(mappedBy = "user")
    private UserProfile profile;

    protected User() {
    }

    public User(String firebaseUid, String mobileNumber, UserRole role, UserStatus status) {
        this.firebaseUid = firebaseUid;
        this.mobileNumber = mobileNumber;
        this.role = role;
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

    public String getFirebaseUid() {
        return firebaseUid;
    }

    public String getMobileNumber() {
        return mobileNumber;
    }

    public UserRole getRole() {
        return role;
    }

    public UserStatus getStatus() {
        return status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public UserProfile getProfile() {
        return profile;
    }

    public boolean isPinSet() {
        return pinSet;
    }

    public Instant getPinUpdatedAt() {
        return pinUpdatedAt;
    }

    public void setPinHash(String pinHash) {
        this.pinHash = pinHash;
        this.pinSet = true;
        this.pinUpdatedAt = Instant.now();
    }
}
