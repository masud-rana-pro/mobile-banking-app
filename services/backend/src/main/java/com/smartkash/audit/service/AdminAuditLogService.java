package com.smartkash.audit.service;

import com.smartkash.audit.entity.AdminAuditLog;
import com.smartkash.audit.enums.AuditAction;
import com.smartkash.audit.enums.AuditTargetType;
import com.smartkash.user.entity.User;

public interface AdminAuditLogService {

    AdminAuditLog recordAdminAction(
            User adminUser,
            AuditAction action,
            AuditTargetType targetType,
            String targetId,
            String details
    );
}
