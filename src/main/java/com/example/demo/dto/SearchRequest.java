package com.example.demo.dto;

import jakarta.validation.constraints.NotBlank;

public class SearchRequest {
    @NotBlank(message = "關鍵字不能為空")
    private String keyword;

    public SearchRequest(String keyword) {
        this.keyword = keyword;
    }

    public String getKeyword() {
        return keyword;
    }

    public void setKeyword(String keyword) {
        this.keyword = keyword;
    }

    @Override
    public String toString() {
        return "SearchRequest{" +
                "keyword='" + keyword + '\'' +
                '}';
    }
}
