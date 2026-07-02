package com.smartkash.user.repository;

import com.smartkash.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByFirebaseUid(String firebaseUid);

    Optional<User> findByMobileNumber(String mobileNumber);

    boolean existsByFirebaseUid(String firebaseUid);

    boolean existsByMobileNumber(String mobileNumber);
}
