package com.example.demo.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;

/**
 * AI 聊天室請求
 */
public class AiChatRequest {

    @NotBlank(message = "訊息不能為空")
    private String message;

    /** 可選：對話歷史，[{"role":"user","content":"..."},{"role":"assistant","content":"..."}] */
    private List<AiMessage> history;

    /** 可選：系統提示詞覆蓋 */
    private String systemPrompt;

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public List<AiMessage> getHistory() { return history; }
    public void setHistory(List<AiMessage> history) { this.history = history; }

    public String getSystemPrompt() { return systemPrompt; }
    public void setSystemPrompt(String systemPrompt) { this.systemPrompt = systemPrompt; }

    /** 對話輪次 */
    public static class AiMessage {
        private String role;   // "user" | "assistant"
        private String content;

        public AiMessage() {}
        public AiMessage(String role, String content) {
            this.role = role;
            this.content = content;
        }

        public String getRole() { return role; }
        public void setRole(String role) { this.role = role; }

        public String getContent() { return content; }
        public void setContent(String content) { this.content = content; }
    }
}
