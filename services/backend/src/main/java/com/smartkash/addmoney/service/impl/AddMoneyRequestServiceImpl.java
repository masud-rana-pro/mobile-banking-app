package com.smartkash.addmoney.service.impl;

import com.smartkash.addmoney.dto.request.CreateAddMoneyRequest;
import com.smartkash.addmoney.dto.response.AddMoneyRequestResponse;
import com.smartkash.addmoney.entity.AddMoneyRequest;
import com.smartkash.addmoney.mapper.AddMoneyRequestMapper;
import com.smartkash.addmoney.repository.AddMoneyRequestRepository;
import com.smartkash.addmoney.service.AddMoneyRequestService;
import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.entity.User;
import com.smartkash.user.enums.UserStatus;
import com.smartkash.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class AddMoneyRequestServiceImpl implements AddMoneyRequestService {

    private final UserRepository userRepository;
    private final AddMoneyRequestRepository addMoneyRequestRepository;
    private final AddMoneyRequestMapper addMoneyRequestMapper;

    public AddMoneyRequestServiceImpl(
            UserRepository userRepository,
            AddMoneyRequestRepository addMoneyRequestRepository,
            AddMoneyRequestMapper addMoneyRequestMapper
    ) {
        this.userRepository = userRepository;
        this.addMoneyRequestRepository = addMoneyRequestRepository;
        this.addMoneyRequestMapper = addMoneyRequestMapper;
    }

    @Override
    @Transactional
    public AddMoneyRequestResponse createCurrentUserRequest(
            JwtPrincipal principal,
            CreateAddMoneyRequest request
    ) {
        User user = currentUser(principal);
        ensureActiveUser(user);
        AddMoneyRequest addMoneyRequest = new AddMoneyRequest(
                user,
                request.amount(),
                request.sourceType(),
                request.note()
        );

        return addMoneyRequestMapper.toResponse(addMoneyRequestRepository.save(addMoneyRequest));
    }

    @Override
    @Transactional(readOnly = true)
    public List<AddMoneyRequestResponse> getCurrentUserRequests(JwtPrincipal principal) {
        User user = currentUser(principal);
        return addMoneyRequestRepository.findByUser_IdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(addMoneyRequestMapper::toResponse)
                .toList();
    }

    private User currentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User account is not created yet."));
    }

    private void ensureActiveUser(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new IllegalArgumentException("Only active users can create Add Money requests.");
        }
    }
}
