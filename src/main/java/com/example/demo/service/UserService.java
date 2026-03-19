package com.example.demo.service;

import com.example.demo.model.User;
import com.example.demo.model.Gender;
import com.example.demo.repository.UserRepository;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.time.LocalDateTime;

import java.util.List;
import java.util.Objects;
import java.util.Optional;

@Service
@Transactional
public class UserService implements UserDetailsService {

    private static final Logger logger = LoggerFactory.getLogger(UserService.class);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));

        // 不在認證過程中更新最後登入時間，避免額外的資料庫寫入
        // 將在成功登入後單獨處理

        return user;
    }

    /**
     * 取得所有用戶
     */
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    /**
     * 根據ID取得用戶
     */
    public Optional<User> getUserById(Long id) {
        return userRepository.findById(Objects.requireNonNull(id));
    }

    /**
     * 根據email取得用戶
     */
    public Optional<User> getUserByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    /**
     * 根據用戶名取得用戶
     */
    public Optional<User> getUserByUsername(String username) {
        return userRepository.findByUsername(username);
    }

    public User save(User user) {
        return userRepository.save(Objects.requireNonNull(user));
    }

    /**
     * 更新用戶最後登入時間
     */
    @Transactional
    public void updateLastLoginTime(String username) {
        try {
            Optional<User> userOpt = userRepository.findByUsername(username);
            if (userOpt.isPresent()) {
                User user = userOpt.get();
                user.setLastLoginAt(java.time.LocalDateTime.now());
                userRepository.save(user);
            }
        } catch (Exception e) {
            // 忽略登入時間更新錯誤，不影響主要登入流程
            logger.warn("更新登入時間失敗: {}", e.getMessage());
        }
    }

    /**
     * 檢查用戶名是否已存在
     */
    public boolean existsByUsername(String username) {
        return userRepository.existsByUsername(username);
    }

    /**
     * 創建新用戶（用於註冊）
     */
    public User createUser(String username, String password, String firstName, String lastName, String email) {
        User user = new User();
        user.setUsername(username);
        // 使用 BCrypt 加密密碼
        user.setPassword(passwordEncoder.encode(password));
        user.setFirstName(firstName);
        user.setLastName(lastName);
        user.setEmail(email);
        return userRepository.save(user);
    }

    public User createUser(String username, String email, String password) {
        if (userRepository.findByUsername(username).isPresent()) {
            throw new RuntimeException("Username already exists");
        }

        if (userRepository.findByEmail(email).isPresent()) {
            throw new RuntimeException("Email already exists");
        }

        User user = new User();
        user.setUsername(username);
        user.setEmail(email);
        user.setPassword(passwordEncoder.encode(password));
        user.setEnabled(true);

        return userRepository.save(user);
    }

    /**
     * 用戶認證（登入）
     */
    public User authenticate(String username, String password) {
        Optional<User> userOpt = userRepository.findByUsername(username);
        if (userOpt.isPresent()) {
            User user = userOpt.get();
            // 使用 BCrypt 驗證密碼
            if (passwordEncoder.matches(password, user.getPassword())) {
                return user;
            }
        }
        return null;
    }

    /**
     * 創建新用戶
     */
    public User createUser(User user) {
        if (userRepository.existsByEmail(user.getEmail())) {
            throw new RuntimeException("Email已存在: " + user.getEmail());
        }
        return userRepository.save(user);
    }

    /**
     * 更新用戶資訊
     */
    public User updateUser(Long id, User userDetails) {
        User user = userRepository.findById(Objects.requireNonNull(id))
                .orElseThrow(() -> new RuntimeException("找不到用戶，ID: " + id));

        // 如果email有變更，檢查新email是否已存在
        if (!user.getEmail().equals(userDetails.getEmail()) &&
                userRepository.existsByEmail(userDetails.getEmail())) {
            throw new RuntimeException("Email已存在: " + userDetails.getEmail());
        }

        user.setFirstName(userDetails.getFirstName());
        user.setLastName(userDetails.getLastName());
        user.setEmail(userDetails.getEmail());
        user.setPhone(userDetails.getPhone());

        return userRepository.save(user);
    }

    /**
     * 刪除用戶
     */
    public void deleteUser(Long id) {
        User user = userRepository.findById(Objects.requireNonNull(id))
                .orElseThrow(() -> new RuntimeException("找不到用戶，ID: " + id));
        userRepository.delete(Objects.requireNonNull(user));
    }

    /**
     * 根據關鍵字搜尋用戶
     */
    public List<User> searchUsers(String keyword) {
        return userRepository.findByNameOrEmailContaining(keyword);
    }

    /**
     * 檢查email是否已存在
     */
    public boolean isEmailExists(String email) {
        return userRepository.existsByEmail(email);
    }

    /**
     * 事務性用戶註冊 - 避免連線洩漏
     */
    @Transactional
    public User registerUser(String username, String email, String password,
            String firstName, String lastName, Gender gender) {
        // 檢查用戶名是否已存在
        if (userRepository.findByUsername(username).isPresent()) {
            throw new RuntimeException("用戶名已存在");
        }

        // 檢查 email 是否已存在
        if (userRepository.findByEmail(email).isPresent()) {
            throw new RuntimeException("Email 已存在");
        }

        // 創建新用戶
        User user = new User();
        user.setUsername(username);
        user.setEmail(email);
        user.setPassword(passwordEncoder.encode(password));
        user.setFirstName(firstName);
        user.setLastName(lastName);
        user.setGender(gender);
        user.setEnabled(true);
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());

        return userRepository.save(user);
    }
}