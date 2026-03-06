package com.example.demo.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

@Schema(description = "JWT 認證請求")
public class JwtRequest {

    @NotBlank(message = "用戶名不能為空")
    @Schema(description = "用戶名", example = "john_doe")
    private String username;

    @NotBlank(message = "密碼不能為空")
    @Schema(description = "密碼", example = "password123")
    private String password;

    public JwtRequest() {
    }

    public JwtRequest(String username, String password) {
        this.username = username;
        this.password = password;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
}
