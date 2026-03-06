package com.example.demo.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.demo.model.ChatMessage;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

        /**
         * 取得兩個用戶之間的所有聊天訊息（按時間排序）
         */
        @Query("SELECT m FROM ChatMessage m WHERE " +
                        "(m.senderId = :userId1 AND m.receiverId = :userId2) OR " +
                        "(m.senderId = :userId2 AND m.receiverId = :userId1) " +
                        "ORDER BY m.timestamp ASC")
        List<ChatMessage> findChatBetweenUsers(@Param("userId1") Long userId1,
                        @Param("userId2") Long userId2);

        /**
         * 取得用戶發送的所有訊息
         */
        List<ChatMessage> findBySenderIdOrderByTimestampDesc(Long senderId);

        /**
         * 取得用戶接收的所有訊息
         */
        List<ChatMessage> findByReceiverIdOrderByTimestampDesc(Long receiverId);

        /**
         * 取得用戶的未讀訊息
         */
        List<ChatMessage> findByReceiverIdAndIsReadFalseOrderByTimestampDesc(Long receiverId);

        /**
         * 計算用戶的未讀訊息數量
         */
        Long countByReceiverIdAndIsReadFalse(Long receiverId);

        /**
         * 取得用戶所有相關的聊天訊息（發送或接收）
         */
        @Query("SELECT m FROM ChatMessage m WHERE " +
                        "m.senderId = :userId OR m.receiverId = :userId " +
                        "ORDER BY m.timestamp DESC")
        List<ChatMessage> findAllMessagesByUserId(@Param("userId") Long userId);

        /**
         * 批次標記指定發送者寄給指定接收者的訊息為已讀
         */
        @Modifying
        @Query("UPDATE ChatMessage m SET m.isRead = true " +
                        "WHERE m.senderId = :senderId AND m.receiverId = :receiverId AND m.isRead = false")
        int markMessagesAsRead(@Param("receiverId") Long receiverId, @Param("senderId") Long senderId);
}
