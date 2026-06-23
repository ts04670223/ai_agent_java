package com.example.demo.exception;

/**
 * 業務邏輯例外（庫存不足、狀態不允許等），回傳 400
 */
public class BusinessException extends RuntimeException {

    public BusinessException(String message) {
        super(message);
    }
}
