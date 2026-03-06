package com.example.demo.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Controller
public class HomeController {

    @GetMapping("/")
    public String redirectToChat() {
        return "redirect:/chat.html";
    }

    @GetMapping("/api")
    public ResponseEntity<Map<String, Object>> home() {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "歡迎使用 Spring Boot 示例應用程式");
        response.put("version", "1.0.0");
        response.put("timestamp", LocalDateTime.now());
        response.put("endpoints", new String[] {
                "GET /api/users - 取得所有用戶",
                "GET /api/users/{id} - 根據ID取得用戶",
                "POST /api/users - 創建新用戶",
                "PUT /api/users/{id} - 更新用戶",
                "DELETE /api/users/{id} - 刪除用戶",
                "GET /api/users/search?keyword= - 搜尋用戶",
                "POST /api/chat/send - 發送聊天訊息",
                "GET /api/chat/history - 取得聊天記錄",
                "GET /api/chat/unread/{userId} - 取得未讀訊息"
        });
        return ResponseEntity.ok(response);
    }

    @GetMapping("/health")
    public ResponseEntity<String> healthCheck() {
        return ResponseEntity.ok("Application is healthy");
    }
}