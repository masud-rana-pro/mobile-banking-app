package com.smartkash.admin.dto.response;

import com.smartkash.audit.enums.AuditAction;
import com.smartkash.audit.enums.AuditTargetType;

import java.time.Instant;

public record AdminAuditLogResponse(
        Long id,
        Long adminUserId,
        String adminMobileNumber,
        AuditAction action,
        AuditTargetType targetType,
        String targetId,
        String details,
        Instant createdAt
) {
}
