package com.example.demo.scheduler;

import java.time.LocalDateTime;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.example.demo.model.Order;
import com.example.demo.model.OrderStatus;
import com.example.demo.repository.OrderRepository;

/**
 * 訂單自動取消排程任務
 *
 * 業務場景：
 * 電商平台通常規定訂單在 N 天內未付款則自動取消，
 * 以釋放預留庫存並通知用戶。
 *
 * 執行時間：每日凌晨 01:00
 * 執行內容：將超過 7 天未付款的 PENDING 訂單自動標記為 CANCELLED
 */
@Component
@ConditionalOnProperty(name = "scheduling.enabled", havingValue = "true", matchIfMissing = true)
public class OrderAutoCloseScheduler {

    private static final Logger log = LoggerFactory.getLogger(OrderAutoCloseScheduler.class);

    /** 超過此天數未付款的訂單自動取消 */
    private static final int AUTO_CANCEL_DAYS = 7;

    private final OrderRepository orderRepository;

    public OrderAutoCloseScheduler(OrderRepository orderRepository) {
        this.orderRepository = orderRepository;
    }

    /**
     * 每日凌晨 1:00 自動取消超時 PENDING 訂單
     */
    @Scheduled(cron = "0 0 1 * * ?")
    @Transactional
    public void autoClosePendingOrders() {
        log.info("[Scheduler] OrderAutoClose 開始執行...");
        LocalDateTime threshold = LocalDateTime.now().minusDays(AUTO_CANCEL_DAYS);
        try {
            List<Order> pendingOrders = orderRepository.findPendingOrdersOlderThan(threshold);
            if (!pendingOrders.isEmpty()) {
                pendingOrders.forEach(order -> order.setStatus(OrderStatus.CANCELLED));
                // 優化 #4：批次儲存取代逐筆 save，減少 N 次 DB round-trip
                orderRepository.saveAll(pendingOrders);
                log.info("[Scheduler] OrderAutoClose 完成，共自動取消 {} 筆訂單", pendingOrders.size());
            } else {
                log.info("[Scheduler] OrderAutoClose 完成，無需取消");
            }
        } catch (Exception ex) {
            log.error("[Scheduler] OrderAutoClose 失敗: {}", ex.getMessage(), ex);
        }
    }
}
