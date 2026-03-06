package com.example.demo.dto;

public class AddToCartRequest {
    private Integer productId;
    private Integer quantity;

    // Constructors
    public AddToCartRequest() {
    }

    public AddToCartRequest(Integer productId, Integer quantity) {
        this.productId = productId;
        this.quantity = quantity;
    }

    // Getters and Setters
    public Integer getProductId() {
        return productId;
    }

    public void setProductId(Integer productId) {
        this.productId = productId;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }
}
