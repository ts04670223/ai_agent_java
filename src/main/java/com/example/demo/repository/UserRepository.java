package com.example.demo.repository;

import com.example.demo.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    /**
     * 根據 username 尋找用戶
     */
    Optional<User> findByUsername(String username);

    /**
     * 檢查 username 是否已存在
     */
    boolean existsByUsername(String username);

    /**
     * 根據 email 尋找用戶
     */
    Optional<User> findByEmail(String email);

    /**
     * 檢查 email 是否已存在
     */
    boolean existsByEmail(String email);

    /**
     * 根據名字模糊搜尋用戶
     */
    List<User> findByFirstNameContainingIgnoreCaseOrLastNameContainingIgnoreCase(String firstName, String lastName);

    /**
     * 使用自定義查詢根據姓名或email搜尋用戶
     */
    @Query("SELECT u FROM User u WHERE u.username LIKE %:keyword% OR u.firstName LIKE %:keyword% OR u.lastName LIKE %:keyword% OR u.email LIKE %:keyword%")
    List<User> findByNameOrEmailContaining(@Param("keyword") String keyword);
}