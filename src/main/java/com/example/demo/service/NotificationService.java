package com.example.demo.service;

import java.util.concurrent.CompletableFuture;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import com.example.demo.model.Order;

@Service
public class NotificationService {

    private static final Logger logger = LoggerFactory.getLogger(NotificationService.class);

    /**
     * 非同步發送訂單確認郵件
     * 使用 @Async 讓此方法在獨立的執行緒中執行，不阻塞主流程
     */
    @Async
    public CompletableFuture<Void> sendOrderConfirmation(Order order) {
        try {
            logger.info("開始發送訂單確認郵件給用戶: {}, 訂單ID: {}", order.getUser().getEmail(), order.getId());
            // TODO: 接入實際郵件服務（如 Spring Mail / SendGrid）
            logger.info("訂單確認通知已處理，訂單ID: {}", order.getId());
        } catch (Exception e) {
            logger.error("訂單通知處理失敗，訂單ID: {}, 錯誤: {}", order.getId(), e.getMessage());
        }
        return CompletableFuture.completedFuture(null);
    }
}
