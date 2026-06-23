package com.example.demo.service;

import java.util.List;
import java.util.Objects;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.demo.exception.BusinessException;
import com.example.demo.exception.ResourceNotFoundException;
import com.example.demo.model.Product;
import com.example.demo.model.User;
import com.example.demo.model.Wishlist;
import com.example.demo.repository.ProductRepository;
import com.example.demo.repository.UserRepository;
import com.example.demo.repository.WishlistRepository;

/**
 * 優化 #3：統一以 username 為主，userId 版本內部轉換後呼叫，消除重複邏輯
 */
@Service
public class WishlistService {

    private final WishlistRepository wishlistRepository;
    private final UserRepository userRepository;
    private final ProductRepository productRepository;

    public WishlistService(WishlistRepository wishlistRepository,
            UserRepository userRepository,
            ProductRepository productRepository) {
        this.wishlistRepository = wishlistRepository;
        this.userRepository = userRepository;
        this.productRepository = productRepository;
    }

    // ── 核心方法（以 User entity 為主）──────────────────────────────

    public List<Wishlist> getWishlistByUser(User user) {
        return wishlistRepository.findByUser(user);
    }

    @Transactional
    public Wishlist addToWishlist(User user, Product product) {
        if (wishlistRepository.existsByUserAndProduct(user, product)) {
            throw new BusinessException("商品已在願望清單中");
        }
        return wishlistRepository.save(new Wishlist(user, product));
    }

    @Transactional
    public void removeFromWishlist(User user, Product product) {
        wishlistRepository.deleteByUserAndProduct(user, product);
    }

    public boolean isInWishlist(User user, Product product) {
        return wishlistRepository.existsByUserAndProduct(user, product);
    }

    // ── 以 username 查詢（Controller 主要使用）──────────────────────

    public List<Wishlist> getWishlistByUsername(String username) {
        return getWishlistByUser(findUserByUsername(username));
    }

    @Transactional
    public Wishlist addToWishlistByUsername(String username, Long productId) {
        return addToWishlist(findUserByUsername(username), findProduct(productId));
    }

    @Transactional
    public void removeFromWishlistByUsername(String username, Long productId) {
        removeFromWishlist(findUserByUsername(username), findProduct(productId));
    }

    public boolean isInWishlistByUsername(String username, Long productId) {
        User user = userRepository.findByUsername(username).orElse(null);
        if (user == null) return false;
        Product product = productRepository.findById(Objects.requireNonNull(productId)).orElse(null);
        if (product == null) return false;
        return isInWishlist(user, product);
    }

    // ── 以 userId 查詢（向下相容）──────────────────────────────────

    public List<Wishlist> getWishlistByUserId(Long userId) {
        return getWishlistByUser(findUserById(userId));
    }

    @Transactional
    public Wishlist addToWishlistByUserId(Long userId, Long productId) {
        return addToWishlist(findUserById(userId), findProduct(productId));
    }

    @Transactional
    public void removeFromWishlistByUserId(Long userId, Long productId) {
        removeFromWishlist(findUserById(userId), findProduct(productId));
    }

    public boolean isInWishlistByUserId(Long userId, Long productId) {
        User user = userRepository.findById(Objects.requireNonNull(userId)).orElse(null);
        if (user == null) return false;
        Product product = productRepository.findById(Objects.requireNonNull(productId)).orElse(null);
        if (product == null) return false;
        return isInWishlist(user, product);
    }

    // ── 私有輔助方法 ────────────────────────────────────────────────

    private User findUserByUsername(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("用戶", "username", username));
    }

    private User findUserById(Long userId) {
        return userRepository.findById(Objects.requireNonNull(userId))
                .orElseThrow(() -> new ResourceNotFoundException("用戶", userId));
    }

    private Product findProduct(Long productId) {
        return productRepository.findById(Objects.requireNonNull(productId))
                .orElseThrow(() -> new ResourceNotFoundException("商品", productId));
    }
}
