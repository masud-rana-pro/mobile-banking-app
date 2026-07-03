package com.smartkash.audit.service.impl;

import com.smartkash.audit.entity.AdminAuditLog;
import com.smartkash.audit.enums.AuditAction;
import com.smartkash.audit.enums.AuditTargetType;
import com.smartkash.audit.repository.AdminAuditLogRepository;
import com.smartkash.audit.service.AdminAuditLogService;
import com.smartkash.user.entity.User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminAuditLogServiceImpl implements AdminAuditLogService {

    private final AdminAuditLogRepository adminAuditLogRepository;

    public AdminAuditLogServiceImpl(AdminAuditLogRepository adminAuditLogRepository) {
        this.adminAuditLogRepository = adminAuditLogRepository;
    }

    @Override
    @Transactional
    public AdminAuditLog recordAdminAction(
            User adminUser,
            AuditAction action,
            AuditTargetType targetType,
            String targetId,
            String details
    ) {
        return adminAuditLogRepository.save(
                new AdminAuditLog(adminUser, action, targetType, targetId, details)
        );
    }
}
