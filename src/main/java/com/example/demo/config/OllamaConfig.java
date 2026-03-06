package com.example.demo.config;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.DefaultUriBuilderFactory;

/**
 * Ollama 本地 LLM RestTemplate 設定
 * baseUrl 預設指向 VM 直接執行的 Ollama: http://localhost:11434
 * （已從 K8s Pod 遷移至 VM 直接安裝，消除雙層虛擬化 overhead）
 */
@Configuration
public class OllamaConfig {

    private static final Logger logger = LoggerFactory.getLogger(OllamaConfig.class);

    @Value("${ollama.base-url:http://ollama:11434}")
    private String ollamaBaseUrl;

    @Value("${ollama.connect-timeout-seconds:5}")
    private int connectTimeoutSeconds;

    @Value("${ollama.read-timeout-seconds:120}")
    private int readTimeoutSeconds;

    @Value("${ollama.model:qwen2.5:0.5b}")
    private String ollamaModel;

    @Bean("ollamaRestTemplate")
    public RestTemplate ollamaRestTemplate() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(connectTimeoutSeconds * 1000);
        factory.setReadTimeout(readTimeoutSeconds * 1000);

        RestTemplate restTemplate = new RestTemplate(factory);
        restTemplate.setUriTemplateHandler(new DefaultUriBuilderFactory(ollamaBaseUrl));
        return restTemplate;
    }

    /**
     * 應用啟動後預熱 Ollama 模型，避免第一次請求的冷啟動延遲（約 5~10 秒）
     * 使用 keep_alive: -1 讓模型永久常駐記憶體
     */
    @Bean
    public CommandLineRunner ollamaWarmup(RestTemplate ollamaRestTemplate) {
        return args -> {
            new Thread(() -> {
                try {
                    logger.info("[Ollama] 預熱模型 {}...", ollamaModel);
                    Map<String, Object> body = new HashMap<>();
                    body.put("model", ollamaModel);
                    body.put("keep_alive", -1);
                    body.put("messages", List.of(Map.of("role", "user", "content", "hi")));
                    body.put("stream", false);
                    Map<?, ?> options = Map.of("num_predict", 1, "num_ctx", 128); // 必須與 LlmService.callOllama 的 num_ctx 一致，避免每次請求重載模型
                    body.put("options", options);
                    ollamaRestTemplate.postForObject("/api/chat", body, Map.class);
                    logger.info("[Ollama] 模型預熱完成，已常駐記憶體");
                } catch (Exception e) {
                    logger.warn("[Ollama] 預熱失敗（Ollama 可能尚未就緒）: {}", e.getMessage());
                }
            }, "ollama-warmup").start();
        };
    }
}
