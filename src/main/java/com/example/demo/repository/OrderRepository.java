package com.example.demo.repository;

import com.example.demo.model.Order;
import com.example.demo.model.OrderStatus;
import com.example.demo.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, Integer> {

    /**
     * 根據用戶查詢所有訂單
     */
    List<Order> findByUserOrderByCreatedAtDesc(User user);

    /**
     * 根據用戶ID查詢訂單
     */
    List<Order> findByUserIdOrderByCreatedAtDesc(Long userId);

    /**
     * 根據訂單編號查詢
     */
    Order findByOrderNumber(String orderNumber);

    /**
     * 根據狀態查詢訂單
     */
    List<Order> findByStatusOrderByCreatedAtDesc(OrderStatus status);

    /**
     * 根據用戶和狀態查詢訂單
     */
    List<Order> findByUserAndStatusOrderByCreatedAtDesc(User user, OrderStatus status);
}
