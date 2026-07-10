package com.smartkash.user.service.impl;

import com.smartkash.common.exception.ResourceNotFoundException;
import com.smartkash.security.JwtPrincipal;
import com.smartkash.user.dto.request.UpdateUserProfileRequest;
import com.smartkash.user.dto.response.UserResponse;
import com.smartkash.user.entity.User;
import com.smartkash.user.entity.UserProfile;
import com.smartkash.user.mapper.UserMapper;
import com.smartkash.user.repository.UserProfileRepository;
import com.smartkash.user.repository.UserRepository;
import com.smartkash.user.service.UserService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.Locale;
import java.util.UUID;

@Service
public class UserServiceImpl implements UserService {

    private static final long MAX_PROFILE_IMAGE_SIZE_BYTES = 2 * 1024 * 1024;

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final UserMapper userMapper;
    private final Path profileImageStorageDirectory;

    public UserServiceImpl(
            UserRepository userRepository,
            UserProfileRepository userProfileRepository,
            UserMapper userMapper,
            @Value("${smartkash.profile-images.storage-directory:src/main/resources/profile-images}")
            String profileImageStorageDirectory
    ) {
        this.userRepository = userRepository;
        this.userProfileRepository = userProfileRepository;
        this.userMapper = userMapper;
        this.profileImageStorageDirectory = Path.of(profileImageStorageDirectory).toAbsolutePath().normalize();
    }

    @Override
    @Transactional(readOnly = true)
    public UserResponse getCurrentUser(JwtPrincipal principal) {
        User user = userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User profile is not created yet."));

        return userMapper.toResponse(user);
    }

    @Override
    @Transactional
    public UserResponse updateCurrentUserProfile(JwtPrincipal principal, UpdateUserProfileRequest request) {
        User user = findCurrentUser(principal);
        UserProfile profile = userProfileRepository.findByUserId(user.getId())
                .orElseGet(() -> new UserProfile(user, null, null, null));

        profile.update(request.fullName(), request.email());
        UserProfile savedProfile = userProfileRepository.save(profile);

        return userMapper.toResponse(user, savedProfile);
    }

    @Override
    @Transactional
    public UserResponse uploadCurrentUserProfileImage(JwtPrincipal principal, MultipartFile image) {
        User user = findCurrentUser(principal);
        UserProfile profile = userProfileRepository.findByUserId(user.getId())
                .orElseGet(() -> new UserProfile(user, null, null, null));

        String imageId = storeProfileImage(image);
        profile.updateAvatarImageId(imageId);
        UserProfile savedProfile = userProfileRepository.save(profile);

        return userMapper.toResponse(user, savedProfile);
    }

    @Override
    @Transactional(readOnly = true)
    public ResponseEntity<Resource> readProfileImage(String imageId) {
        String safeImageId = sanitizeImageId(imageId);
        Path imagePath = profileImageStorageDirectory.resolve(safeImageId).normalize();
        if (!imagePath.startsWith(profileImageStorageDirectory) || !Files.exists(imagePath)) {
            throw new ResourceNotFoundException("Profile image was not found.");
        }

        try {
            Resource resource = new UrlResource(imagePath.toUri());
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentTypeForImageId(safeImageId)))
                    .cacheControl(CacheControl.maxAge(Duration.ofHours(6)).cachePublic())
                    .body(resource);
        } catch (MalformedURLException exception) {
            throw new ResourceNotFoundException("Profile image was not found.");
        }
    }

    private User findCurrentUser(JwtPrincipal principal) {
        return userRepository.findByFirebaseUid(principal.firebaseUid())
                .orElseThrow(() -> new ResourceNotFoundException("User profile is not created yet."));
    }

    private String storeProfileImage(MultipartFile image) {
        if (image == null || image.isEmpty()) {
            throw new IllegalArgumentException("Profile image is required.");
        }

        if (image.getSize() > MAX_PROFILE_IMAGE_SIZE_BYTES) {
            throw new IllegalArgumentException("Profile image must be 2 MB or smaller.");
        }

        String extension = extensionForContentType(image.getContentType());
        String imageId = UUID.randomUUID() + "." + extension;
        Path targetPath = profileImageStorageDirectory.resolve(imageId).normalize();

        if (!targetPath.startsWith(profileImageStorageDirectory)) {
            throw new IllegalArgumentException("Invalid profile image path.");
        }

        try {
            Files.createDirectories(profileImageStorageDirectory);
            image.transferTo(targetPath);
            return imageId;
        } catch (IOException exception) {
            throw new IllegalStateException("Could not save profile image.");
        }
    }

    private String sanitizeImageId(String imageId) {
        if (!StringUtils.hasText(imageId) || imageId.contains("/") || imageId.contains("\\")) {
            throw new ResourceNotFoundException("Profile image was not found.");
        }
        return imageId;
    }

    private String extensionForContentType(String contentType) {
        String normalized = contentType == null ? "" : contentType.toLowerCase(Locale.ROOT);
        return switch (normalized) {
            case MediaType.IMAGE_JPEG_VALUE -> "jpg";
            case MediaType.IMAGE_PNG_VALUE -> "png";
            case "image/webp" -> "webp";
            default -> throw new IllegalArgumentException("Profile image must be JPG, PNG, or WEBP.");
        };
    }

    private String contentTypeForImageId(String imageId) {
        String lower = imageId.toLowerCase(Locale.ROOT);
        if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
            return MediaType.IMAGE_JPEG_VALUE;
        }
        if (lower.endsWith(".png")) {
            return MediaType.IMAGE_PNG_VALUE;
        }
        if (lower.endsWith(".webp")) {
            return "image/webp";
        }
        return MediaType.APPLICATION_OCTET_STREAM_VALUE;
    }
}
