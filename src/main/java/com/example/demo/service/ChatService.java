package com.example.demo.service;

import java.util.List;
import java.util.Objects;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.demo.model.ChatMessage;
import com.example.demo.repository.ChatMessageRepository;

@Service
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;

    public ChatService(ChatMessageRepository chatMessageRepository) {
        this.chatMessageRepository = chatMessageRepository;
    }

    /**
     * 發送訊息
     */
    @Transactional
    public ChatMessage sendMessage(Long senderId, Long receiverId, String message) {
        ChatMessage chatMessage = new ChatMessage(senderId, receiverId, message);
        return chatMessageRepository.save(chatMessage);
    }

    /**
     * 取得兩個用戶之間的聊天記錄
     */
    @Transactional(readOnly = true)
    public List<ChatMessage> getChatHistory(Long userId1, Long userId2) {
        return chatMessageRepository.findChatBetweenUsers(userId1, userId2);
    }

    /**
     * 取得用戶發送的所有訊息
     */
    @Transactional(readOnly = true)
    public List<ChatMessage> getSentMessages(Long userId) {
        return chatMessageRepository.findBySenderIdOrderByTimestampDesc(userId);
    }

    /**
     * 取得用戶接收的所有訊息
     */
    @Transactional(readOnly = true)
    public List<ChatMessage> getReceivedMessages(Long userId) {
        return chatMessageRepository.findByReceiverIdOrderByTimestampDesc(userId);
    }

    /**
     * 取得用戶的未讀訊息
     */
    @Transactional(readOnly = true)
    public List<ChatMessage> getUnreadMessages(Long userId) {
        return chatMessageRepository.findByReceiverIdAndIsReadFalseOrderByTimestampDesc(userId);
    }

    /**
     * 計算未讀訊息數量
     */
    @Transactional(readOnly = true)
    public Long getUnreadCount(Long userId) {
        return chatMessageRepository.countByReceiverIdAndIsReadFalse(userId);
    }

    /**
     * 標記訊息為已讀
     */
    @Transactional
    public boolean markAsRead(Long messageId) {
        Optional<ChatMessage> messageOpt = chatMessageRepository.findById(Objects.requireNonNull(messageId));
        if (messageOpt.isPresent()) {
            ChatMessage message = messageOpt.get();
            message.setIsRead(true);
            chatMessageRepository.save(message);
            return true;
        }
        return false;
    }

    /**
     * 標記兩個用戶之間的所有訊息為已讀（使用 bulk update，避免 N+1）
     */
    @Transactional
    public void markChatAsRead(Long receiverId, Long senderId) {
        chatMessageRepository.markMessagesAsRead(receiverId, senderId);
    }

    /**
     * 取得用戶所有相關的訊息
     */
    @Transactional(readOnly = true)
    public List<ChatMessage> getAllUserMessages(Long userId) {
        return chatMessageRepository.findAllMessagesByUserId(userId);
    }

    /**
     * 刪除訊息
     */
    @Transactional
    public boolean deleteMessage(Long messageId) {
        if (chatMessageRepository.existsById(Objects.requireNonNull(messageId))) {
            chatMessageRepository.deleteById(Objects.requireNonNull(messageId));
            return true;
        }
        return false;
    }

    /**
     * 取得訊息詳情
     */
    @Transactional(readOnly = true)
    public Optional<ChatMessage> getMessageById(Long messageId) {
        return chatMessageRepository.findById(Objects.requireNonNull(messageId));
    }
}
