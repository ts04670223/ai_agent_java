package com.example.demo.aspect;

import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 日誌切面
 *
 * 學習重點：
 * 1. @Aspect + @Component：宣告為切面 Bean
 * 2. @Pointcut：定義切入點表達式（哪些方法要攔截）
 * 3. @Around：環繞通知，可在方法前後都執行邏輯
 *
 * 功能：
 * - 記錄所有 Controller 方法的 HTTP 請求資訊與執行時間
 * - 記錄 Service 層超過 500ms 的慢方法警告
 */
@Aspect
@Component
public class LoggingAspect {

    private static final Logger log = LoggerFactory.getLogger(LoggingAspect.class);

    /** 用於將物件序列化為 JSON 字串 */
    @Autowired
    private ObjectMapper objectMapper;

    /** 超過此閾值的 Service 方法視為慢方法（毫秒） */
    private static final long SLOW_METHOD_THRESHOLD_MS = 500L;

    /**
     * 切入點：com.example.demo.controller 套件下所有類別的所有方法
     */
    @Pointcut("execution(* com.example.demo.controller..*(..))")
    public void controllerMethods() {}

    /**
     * 切入點：com.example.demo.service 套件下所有類別的所有方法
     */
    @Pointcut("execution(* com.example.demo.service..*(..))")
    public void serviceMethods() {}

    /**
     * @Around 環繞通知：攔截所有 Controller 方法
     * 記錄：HTTP 方法、請求 URI、目前用戶、執行耗時
     *
     * @param joinPoint 連接點，可用來執行原始方法 (joinPoint.proceed())
     */
    /** 輪詢類端點，不記錄 log（避免大量重複雜訊） */
    private static final java.util.List<String> POLLING_URIS = java.util.List.of(
        "/api/chat/unread-count",
        "/api/chat/history",
        "/api/wishlist",
        "/api/cart/",
        "/api/products"
    );

    @Around("controllerMethods()")
    public Object logControllerExecution(ProceedingJoinPoint joinPoint) throws Throwable {
        long startTime = System.currentTimeMillis();

        String requestInfo = getRequestInfo();

        // 輪詢類端點（僅 GET）不記錄 log（避免大量重複雜訊）
        if (requestInfo.startsWith("GET ") && POLLING_URIS.stream().anyMatch(requestInfo::contains)) {
            return joinPoint.proceed();
        }

        String currentUser = getCurrentUsername();
        String requestId = java.util.UUID.randomUUID().toString().substring(0, 8);
        MDC.put("requestId", requestId);

        // 格式化傳入參數為 JSON，方便記錄
        Object[] args = joinPoint.getArgs();
        String argsJson = (args != null && args.length > 0)
                ? toJson(args)
                : "[]";
        log.info("[API] 開始 | {} | 用戶: {} | 參數: {}", requestInfo, currentUser, argsJson);

        try {
            // 執行原始方法
            Object result = joinPoint.proceed();

            // 記錄回傳結果（取出 ResponseEntity body）與耗時
            long duration = System.currentTimeMillis() - startTime;
            Object body = (result instanceof ResponseEntity<?> re) ? re.getBody() : result;
            log.info("[API] 完成 | {} | 耗時: {}ms | 用戶: {} | 回傳: {}",
                    requestInfo, duration, currentUser, toJson(body));
            return result;
        } catch (Exception ex) {
            long duration = System.currentTimeMillis() - startTime;
            log.warn("[API] 例外 | {} | 耗時: {}ms | 原因: {} | 用戶: {}",
                    requestInfo, duration, ex.getMessage(), currentUser);
            throw ex;
        } finally {
            MDC.remove("requestId");
        }
    }

    /**
     * @Around 環繞通知：攔截所有 Service 方法
     * 當方法執行超過門檻值時發出 WARN 警告（效能監控）
     */
    @Around("serviceMethods()")
    public Object logSlowServiceMethods(ProceedingJoinPoint joinPoint) throws Throwable {
        long startTime = System.currentTimeMillis();
        Object result = joinPoint.proceed();
        long duration = System.currentTimeMillis() - startTime;

        if (duration > SLOW_METHOD_THRESHOLD_MS) {
            log.warn("[SLOW] {} 耗時 {}ms，超過 {}ms 門檻值",
                    joinPoint.getSignature().toShortString(),
                    duration,
                    SLOW_METHOD_THRESHOLD_MS);
        }

        return result;
    }

    /**
     * 將物件序列化為 JSON 字串；若失敗則退回 toString()
     */
    private String toJson(Object obj) {
        if (obj == null) return "null";
        try {
            return objectMapper.writeValueAsString(obj);
        } catch (Exception e) {
            return obj.toString();
        }
    }

    /**
     * 取得當前 HTTP 請求的方法與 URI
     */
    private String getRequestInfo() {
        try {
            ServletRequestAttributes attrs =
                    (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attrs != null) {
                HttpServletRequest request = attrs.getRequest();
                return request.getMethod() + " " + request.getRequestURI();
            }
        } catch (Exception ignored) {
        }
        return "UNKNOWN";
    }

    /**
     * 取得當前登入用戶名稱（未登入則回傳 "anonymous"）
     */
    private String getCurrentUsername() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.isAuthenticated()
                    && !"anonymousUser".equals(auth.getPrincipal())) {
                return auth.getName();
            }
        } catch (Exception ignored) {
        }
        return "anonymous";
    }
}
