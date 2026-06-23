package com.example.demo.exception;

/**
 * 優化 #6：自訂資源不存在例外，取代 GlobalExceptionHandler 中的字串比對判斷
 */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }

    public ResourceNotFoundException(String resourceName, Long id) {
        super("找不到" + resourceName + "，ID: " + id);
    }

    public ResourceNotFoundException(String resourceName, Integer id) {
        super("找不到" + resourceName + "，ID: " + id);
    }

    public ResourceNotFoundException(String resourceName, String field, String value) {
        super("找不到" + resourceName + "，" + field + ": " + value);
    }
}
