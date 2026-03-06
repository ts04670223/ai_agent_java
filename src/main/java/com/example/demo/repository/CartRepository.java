package com.example.demo.repository;

import com.example.demo.model.Cart;
import com.example.demo.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CartRepository extends JpaRepository<Cart, Integer> {

    /**
     * 根據用戶查詢購物車
     */
    Optional<Cart> findByUser(User user);

    /**
     * 根據用戶ID查詢購物車
     */
    Optional<Cart> findByUserId(Long userId);
}
