package com.example.demo.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

import com.example.demo.model.Cart;

/**
 * 優化 #2：購物車回應 DTO，統一回應格式，取代 Controller 中手動組裝 Map
 */
public class CartResponseDto {

    private Long id;
    private Long userId;
    private Integer itemCount;
    private BigDecimal total;
    private List<CartItemDto> items;

    public static CartResponseDto from(Cart cart) {
        CartResponseDto dto = new CartResponseDto();
        dto.id = cart.getId().longValue();
        dto.userId = cart.getUser().getId();
        dto.items = cart.getItems().stream()
                .map(CartItemDto::from)
                .collect(Collectors.toList());
        dto.itemCount = dto.items.size();
        dto.total = cart.getItems().stream()
                .map(item -> item.getPrice().multiply(BigDecimal.valueOf(item.getQuantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        return dto;
    }

    public Long getId() { return id; }
    public Long getUserId() { return userId; }
    public Integer getItemCount() { return itemCount; }
    public BigDecimal getTotal() { return total; }
    public List<CartItemDto> getItems() { return items; }
}
