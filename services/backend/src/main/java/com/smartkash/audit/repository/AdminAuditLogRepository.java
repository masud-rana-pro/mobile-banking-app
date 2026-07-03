package com.smartkash.audit.repository;

import com.smartkash.audit.entity.AdminAuditLog;
import com.smartkash.audit.enums.AuditAction;
import com.smartkash.audit.enums.AuditTargetType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AdminAuditLogRepository extends JpaRepository<AdminAuditLog, Long> {

    List<AdminAuditLog> findAllByOrderByCreatedAtDesc();

    List<AdminAuditLog> findByAdminUser_IdOrderByCreatedAtDesc(Long adminUserId);

    List<AdminAuditLog> findByActionOrderByCreatedAtDesc(AuditAction action);

    List<AdminAuditLog> findByTargetTypeAndTargetIdOrderByCreatedAtDesc(
            AuditTargetType targetType,
            String targetId
    );
}
