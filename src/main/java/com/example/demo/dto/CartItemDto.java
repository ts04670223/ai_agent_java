package com.example.demo.dto;

import java.math.BigDecimal;

import com.example.demo.model.CartItem;

/**
 * 優化 #2：購物車項目 DTO，取代 Controller 中手動組裝 Map
 */
public class CartItemDto {

    private Long id;
    private Long productId;
    private String productName;
    private BigDecimal price;
    private BigDecimal productPrice;
    private Integer quantity;
    private BigDecimal subtotal;

    public static CartItemDto from(CartItem item) {
        CartItemDto dto = new CartItemDto();
        dto.id = item.getId().longValue();
        dto.productId = item.getProduct().getId();
        dto.productName = item.getProduct().getName();
        dto.price = item.getPrice();
        dto.productPrice = item.getProduct().getPrice();
        dto.quantity = item.getQuantity();
        dto.subtotal = item.getSubtotal();
        return dto;
    }

    public Long getId() { return id; }
    public Long getProductId() { return productId; }
    public String getProductName() { return productName; }
    public BigDecimal getPrice() { return price; }
    public BigDecimal getProductPrice() { return productPrice; }
    public Integer getQuantity() { return quantity; }
    public BigDecimal getSubtotal() { return subtotal; }
}
