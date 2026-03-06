package com.example.demo.dto;

public class CreateOrderRequest {
    private Long userId;
    private String shippingAddress;
    private String phone;
    private String note;

    // Constructors
    public CreateOrderRequest() {
    }

    public CreateOrderRequest(Long userId, String shippingAddress, String phone, String note) {
        this.userId = userId;
        this.shippingAddress = shippingAddress;
        this.phone = phone;
        this.note = note;
    }

    // Getters and Setters
    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getShippingAddress() {
        return shippingAddress;
    }

    public void setShippingAddress(String shippingAddress) {
        this.shippingAddress = shippingAddress;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }
}
