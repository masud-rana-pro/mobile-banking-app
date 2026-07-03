package com.smartkash.admin.mapper;

import com.smartkash.admin.dto.response.AdminAuditLogResponse;
import com.smartkash.audit.entity.AdminAuditLog;
import com.smartkash.user.entity.User;
import org.springframework.stereotype.Component;

@Component
public class AdminAuditLogMapper {

    public AdminAuditLogResponse toResponse(AdminAuditLog auditLog) {
        User adminUser = auditLog.getAdminUser();
        return new AdminAuditLogResponse(
                auditLog.getId(),
                adminUser.getId(),
                adminUser.getMobileNumber(),
                auditLog.getAction(),
                auditLog.getTargetType(),
                auditLog.getTargetId(),
                auditLog.getDetails(),
                auditLog.getCreatedAt()
        );
    }
}
