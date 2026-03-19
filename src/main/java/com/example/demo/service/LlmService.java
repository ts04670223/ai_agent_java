package com.example.demo.service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.function.Consumer;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import com.example.demo.dto.AiChatRequest;
import com.example.demo.model.Product;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Ollama 本地 LLM 服務
 * <p>
 * 直接呼叫 Ollama REST API（POST /api/chat），不依賴任何第三方 AI SDK。
 * 模型：qwen2.5:0.5b Q4_K_M（~379MB，繁體中文優化，可在 1GB 記憶體內執行）
 */
@Service
public class LlmService {

    private static final Logger logger = LoggerFactory.getLogger(LlmService.class);

    private static final String CHAT_PATH = "/api/chat";

    private static final String DEFAULT_SYSTEM_PROMPT =
            // 精簡提示詞：qwen2.5:0.5b num_ctx=256，系統提示需控制在 ~30 tokens 以內
            "你是購物助手。用繁體中文簡短回答。非購物問題請拒絕。";

    @Value("${ollama.model:qwen2.5:0.5b}")
    private String model;

    private final RestTemplate ollamaRestTemplate;

    public LlmService(@Qualifier("ollamaRestTemplate") RestTemplate ollamaRestTemplate) {
        this.ollamaRestTemplate = ollamaRestTemplate;
    }

    /**
     * 通用對話：帶可選的歷史記錄（同步，等待全部回應後才回傳）
     */
    public String chat(String userMessage, List<AiChatRequest.AiMessage> history, String customSystemPrompt) {
        String systemPrompt = (customSystemPrompt != null && !customSystemPrompt.isBlank())
                ? customSystemPrompt
                : DEFAULT_SYSTEM_PROMPT;

        List<Map<String, String>> messages = buildMessages(systemPrompt, history, userMessage);
        return callOllama(messages);
    }

    /**
     * 通用對話（Streaming）：邊生成邊透過 tokenConsumer 回呼每個 token
     * 前端使用 SSE 接收，第一個 token 約 10-15 秒即可顯示（體感大幅縮短）
     *
     * @param tokenConsumer 每個 token 的回呼（在呼叫端執行緒中被呼叫）
     */
    public void chatStream(String userMessage,
            List<AiChatRequest.AiMessage> history,
            String customSystemPrompt,
            Consumer<String> tokenConsumer) {
        String systemPrompt = (customSystemPrompt != null && !customSystemPrompt.isBlank())
                ? customSystemPrompt
                : DEFAULT_SYSTEM_PROMPT;
        List<Map<String, String>> messages = buildMessages(systemPrompt, history, userMessage);
        callOllamaStream(messages, tokenConsumer);
    }

    /**
     * 商品推薦：根據使用者意圖從現有商品清單中推薦
     */
    public String recommendProducts(List<Product> products, String userIntent) {
        if (products == null || products.isEmpty()) {
            return "目前沒有可推薦的商品。";
        }

        String productList = products.stream()
                .limit(20) // 限制 token 數量
                .map(p -> String.format("- %s（%s，$%.0f，庫存：%d）",
                        p.getName(),
                        p.getCategory() != null ? p.getCategory() : "未分類",
                        p.getPrice(),
                        p.getStock()))
                .collect(Collectors.joining("\n"));

        String systemPrompt = """
                你是購物推薦系統。根據用戶意圖，從以下商品清單中推薦最多3項最合適的商品，\
                並說明推薦原因。只能推薦清單中存在的商品，回應使用繁體中文。

                商品清單：
                """ + productList;

        List<Map<String, String>> messages = buildMessages(systemPrompt, null, userIntent);
        return callOllama(messages);
    }

    /**
     * 智慧搜尋：將自然語言查詢轉換為關鍵字
     * 回傳 JSON 格式：{"keywords": ["..."], "category": "..."}
     */
    public String extractSearchKeywords(String naturalLanguageQuery) {
        String systemPrompt = "你是搜尋輔助系統。將用戶的自然語言查詢轉換為適合商品搜尋的關鍵字。" +
                "只回傳 JSON，格式：{\"keywords\":[\"關鍵字1\",\"關鍵字2\"],\"category\":\"類別或空字串\"}。" +
                "不要有任何其他文字。";

        List<Map<String, String>> messages = buildMessages(systemPrompt, null, naturalLanguageQuery);
        return callOllama(messages);
    }

    /**
     * 商品描述摘要
     */
    public String summarizeProduct(Product product) {
        String systemPrompt = "你是商品介紹撰寫員。根據商品資訊，以2-3句繁體中文撰寫吸引人的商品摘要。";

        String userMessage = String.format(
                "商品名稱：%s\n分類：%s\n價格：$%.0f\n描述：%s",
                product.getName(),
                product.getCategory() != null ? product.getCategory() : "未分類",
                product.getPrice(),
                product.getDescription() != null ? product.getDescription() : "無描述");

        List<Map<String, String>> messages = buildMessages(systemPrompt, null, userMessage);
        return callOllama(messages);
    }

    // ─── 私有輔助方法 ──────────────────────────────────────────────────────────

    /**
     * 串流呼叫 Ollama /api/chat（stream: true）
     * 逐行解析 NDJSON，每個 token 回呼 tokenConsumer
     * 結束時 tokenConsumer.accept(null) 表示完成
     */
    @SuppressWarnings("unchecked")
    private void callOllamaStream(List<Map<String, String>> messages, Consumer<String> tokenConsumer) {
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", model);
        requestBody.put("messages", messages);
        requestBody.put("stream", true);
        requestBody.put("keep_alive", -1);

        Map<String, Object> options = new HashMap<>();
        options.put("num_ctx", 128);
        options.put("num_predict", 20);
        options.put("num_thread", 4);
        options.put("temperature", 0.1);
        requestBody.put("options", options);

        ObjectMapper mapper = new ObjectMapper();
        try {
            ollamaRestTemplate.execute(
                    CHAT_PATH,
                    Objects.requireNonNull(HttpMethod.POST),
                    req -> {
                        req.getHeaders().setContentType(MediaType.APPLICATION_JSON);
                        mapper.writeValue(req.getBody(), requestBody);
                    },
                    resp -> {
                        try (BufferedReader reader = new BufferedReader(
                                new InputStreamReader(resp.getBody(), StandardCharsets.UTF_8))) {
                            String line;
                            while ((line = reader.readLine()) != null) {
                                if (line.isBlank())
                                    continue;
                                try {
                                    Map<String, Object> chunk = mapper.readValue(line, Map.class);
                                    Map<?, ?> msg = (Map<?, ?>) chunk.get("message");
                                    if (msg != null) {
                                        String content = (String) msg.get("content");
                                        if (content != null && !content.isEmpty()) {
                                            tokenConsumer.accept(content);
                                        }
                                    }
                                    if (Boolean.TRUE.equals(chunk.get("done")))
                                        break;
                                } catch (JsonProcessingException parseEx) {
                                    logger.debug("[Ollama Stream] 跳過無法解析的行: {}", line);
                                }
                            }
                        }
                        tokenConsumer.accept(null); // 串流結束訊號
                        return null;
                    });
        } catch (ResourceAccessException e) {
            logger.warn("[Ollama Stream] 連線失敗: {}", e.getMessage());
            throw new RuntimeException("AI 服務暫時無法使用，請稍後再試");
        } catch (RuntimeException e) {
            logger.error("[Ollama Stream] 呼叫失敗: {}", e.getMessage(), e);
            throw new RuntimeException("AI 服務發生錯誤: " + e.getMessage());
        }
    }

    /**
     * 輕量健康檢查：呼叫 /api/tags 確認 Ollama 可連線且模型已載入
     * 不做 LLM 推理，回應約 <100ms
     */
    @SuppressWarnings("unchecked")
    public Map<String, Object> checkHealth() {
        try {
            Map<String, Object> response = ollamaRestTemplate.getForObject("/api/tags", Map.class);
            if (response == null) {
                throw new RuntimeException("Ollama 未回應");
            }
            java.util.List<?> models = (java.util.List<?>) response.get("models");
            long modelCount = models != null ? models.size() : 0;
            boolean modelLoaded = models != null && models.stream()
                    .anyMatch(m -> m instanceof Map &&
                            model.equals(((Map<?, ?>) m).get("name")));
            return Map.of(
                    "status", "ok",
                    "model", model,
                    "modelLoaded", modelLoaded,
                    "totalModels", modelCount);
        } catch (ResourceAccessException e) {
            logger.warn("Ollama 健康檢查失敗（連線）：{}", e.getMessage());
            throw new RuntimeException("Ollama 服務無法連線");
        } catch (RuntimeException e) {
            logger.error("Ollama 健康檢查失敗：{}", e.getMessage());
            throw new RuntimeException("Ollama 健康檢查錯誤: " + e.getMessage());
        }
    }

    @SuppressWarnings("unchecked")
    private String callOllama(List<Map<String, String>> messages) {
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", model);
        requestBody.put("messages", messages);
        requestBody.put("stream", false);
        // keep_alive: -1 (數字) 讓模型永久常駐記憶體，避免每次請求重新載入
        requestBody.put("keep_alive", -1);

        // 生成參數：純 CPU 環境最佳化（實測 0.27 tok/s）
        // num_ctx=128：prefill token 減半，節省 ~10-20 秒
        // num_predict=20：20 × 3.7s = 74 秒，遠低於 270s timeout
        // num_thread=4：配合 VM 4 核心
        Map<String, Object> options = new HashMap<>();
        options.put("num_ctx", 128); // context window 128（prefill 最小化）
        options.put("num_predict", 20); // 最多生成 20 token（約 10-14 個中文字）
        options.put("num_thread", 4); // 配合 VM 4 核心
        options.put("temperature", 0.1); // 幾乎 greedy decode，省略 sampling 開銷
        requestBody.put("options", options);

        try {
            Map<String, Object> response = ollamaRestTemplate.postForObject(
                    CHAT_PATH, requestBody, Map.class);

            if (response == null) {
                return "AI 服務未回應";
            }

            Map<String, Object> message = (Map<String, Object>) response.get("message");
            if (message == null) {
                // 舊版 Ollama /api/generate 格式
                Object responseText = response.get("response");
                return responseText != null ? responseText.toString() : "無回應內容";
            }
            return message.getOrDefault("content", "無回應內容").toString();

        } catch (ResourceAccessException e) {
            logger.warn("Ollama 服務無法連線（{}），確認 Pod 是否已啟動", e.getMessage());
            throw new RuntimeException("AI 服務暫時無法使用，請稍後再試");
        } catch (RuntimeException e) {
            logger.error("呼叫 Ollama 失敗: {}", e.getMessage(), e);
            throw new RuntimeException("AI 服務發生錯誤: " + e.getMessage());
        }
    }

    private List<Map<String, String>> buildMessages(
            String systemPrompt,
            List<AiChatRequest.AiMessage> history,
            String userMessage) {

        List<Map<String, String>> messages = new ArrayList<>();

        // 系統提示詞
        messages.add(Map.of("role", "system", "content", systemPrompt));

        // 歷史對話（最多保留最近 3 輪 = 6 條，避免 token 超限影響速度）
        if (history != null && !history.isEmpty()) {
            int start = Math.max(0, history.size() - 6); // 3輪 = 6 條
            for (AiChatRequest.AiMessage h : history.subList(start, history.size())) {
                messages.add(Map.of("role", h.getRole(), "content", h.getContent()));
            }
        }

        // 當前使用者訊息
        messages.add(Map.of("role", "user", "content", userMessage));
        return messages;
    }
}
