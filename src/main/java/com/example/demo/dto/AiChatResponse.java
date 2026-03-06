package com.example.demo.dto;

/**
 * AI 聊天回應
 */
public class AiChatResponse {

    private String reply;
    private String model;
    private boolean success;
    private String error;

    public AiChatResponse() {}

    public static AiChatResponse ok(String reply, String model) {
        AiChatResponse r = new AiChatResponse();
        r.reply = reply;
        r.model = model;
        r.success = true;
        return r;
    }

    public static AiChatResponse fail(String error) {
        AiChatResponse r = new AiChatResponse();
        r.error = error;
        r.success = false;
        return r;
    }

    public String getReply() { return reply; }
    public void setReply(String reply) { this.reply = reply; }

    public String getModel() { return model; }
    public void setModel(String model) { this.model = model; }

    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }

    public String getError() { return error; }
    public void setError(String error) { this.error = error; }
}
