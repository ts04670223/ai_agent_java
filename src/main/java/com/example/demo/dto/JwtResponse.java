package com.example.demo.dto;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "JWT 認證響應")
public class JwtResponse {

    @Schema(description = "JWT Token", example = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpX...")
    private String token;

    @Schema(description = "Token 類型", example = "Bearer")
    private String type = "Bearer";

    @Schema(description = "用戶名", example = "john_doe")
    private String username;

    @Schema(description = "用戶角色", example = "CUSTOMER")
    private String role;

    public JwtResponse() {
    }

    public JwtResponse(String token, String username, String role) {
        this.token = token;
        this.username = username;
        this.role = role;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }
}