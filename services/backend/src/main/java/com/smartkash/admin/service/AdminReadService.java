package com.smartkash.admin.service;

import com.smartkash.addmoney.dto.response.AddMoneyRequestResponse;
import com.smartkash.admin.dto.response.AdminAuditLogResponse;
import com.smartkash.loan.dto.response.LoanRequestResponse;
import com.smartkash.recharge.dto.response.MobileRechargeResponse;
import com.smartkash.transaction.dto.response.TransactionResponse;
import com.smartkash.user.dto.response.UserResponse;

import java.util.List;

public interface AdminReadService {

    List<UserResponse> getUsers();

    List<TransactionResponse> getTransactions();

    List<AddMoneyRequestResponse> getAddMoneyRequests();

    List<LoanRequestResponse> getLoanRequests();

    List<MobileRechargeResponse> getRecharges();

    List<TransactionResponse> getPayments();

    List<AdminAuditLogResponse> getAuditLogs();
}
