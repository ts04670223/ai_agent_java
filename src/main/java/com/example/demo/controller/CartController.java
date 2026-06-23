package com.example.demo.controller;

import java.math.BigDecimal;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.ApiResponse;
import com.example.demo.dto.CartResponseDto;
import com.example.demo.model.Cart;
import com.example.demo.service.CartService;

/**
 * 購物車控制器
 * 優化 #1：消除重複的總金額計算邏輯（移至 CartResponseDto）
 * 優化 #2：統一使用 ApiResponse<CartResponseDto> 取代手動組裝 Map
 * 優化 #7：cartItemId 型別統一為 Long
 */
@RestController
@RequestMapping("/api/cart")
public class CartController {

    private static final Logger log = LoggerFactory.getLogger(CartController.class);

    private final CartService cartService;

    public CartController(CartService cartService) {
        this.cartService = cartService;
    }

    /**
     * 取得用戶的購物車
     * GET /api/cart/{userId}
     */
    @GetMapping("/{userId}")
    public ResponseEntity<ApiResponse<CartResponseDto>> getCart(@PathVariable Long userId) {
        Cart cart = cartService.getCartByUserId(userId);
        return ResponseEntity.ok(ApiResponse.success("取得購物車成功", CartResponseDto.from(cart)));
    }

    /**
     * 添加商品到購物車
     * POST /api/cart/{userId}/items
     */
    @PostMapping("/{userId}/items")
    public ResponseEntity<ApiResponse<CartResponseDto>> addItem(
            @PathVariable Long userId,
            @RequestParam Long productId,
            @RequestParam(defaultValue = "1") Integer quantity) {
        Cart cart = cartService.addItemToCart(userId, productId, quantity);
        log.info("加入購物車: userId={}, productId={}, quantity={}", userId, productId, quantity);
        return ResponseEntity.ok(ApiResponse.success("商品已添加到購物車", CartResponseDto.from(cart)));
    }

    /**
     * 更新購物車項目數量
     * PUT /api/cart/{userId}/items/{cartItemId}
     */
    @PutMapping("/{userId}/items/{cartItemId}")
    public ResponseEntity<ApiResponse<CartResponseDto>> updateItemQuantity(
            @PathVariable Long userId,
            @PathVariable Long cartItemId,
            @RequestParam Integer quantity) {
        Cart cart = cartService.updateCartItemQuantity(userId, cartItemId, quantity);
        return ResponseEntity.ok(ApiResponse.success("數量已更新", CartResponseDto.from(cart)));
    }

    /**
     * 從購物車移除項目
     * DELETE /api/cart/{userId}/items/{cartItemId}
     */
    @DeleteMapping("/{userId}/items/{cartItemId}")
    public ResponseEntity<ApiResponse<CartResponseDto>> removeItem(
            @PathVariable Long userId,
            @PathVariable Long cartItemId) {
        Cart cart = cartService.removeItemFromCart(userId, cartItemId);
        log.info("移除購物車商品: userId={}, cartItemId={}", userId, cartItemId);
        return ResponseEntity.ok(ApiResponse.success("商品已移除", CartResponseDto.from(cart)));
    }

    /**
     * 清空購物車
     * DELETE /api/cart/{userId}
     */
    @DeleteMapping("/{userId}")
    public ResponseEntity<ApiResponse<Void>> clearCart(@PathVariable Long userId) {
        cartService.clearCart(userId);
        log.info("清空購物車: userId={}", userId);
        return ResponseEntity.ok(ApiResponse.success("購物車已清空", null));
    }

    /**
     * 取得購物車總金額
     * GET /api/cart/{userId}/total
     */
    @GetMapping("/{userId}/total")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getCartTotal(@PathVariable Long userId) {
        BigDecimal total = cartService.calculateCartTotal(userId);
        int itemCount = cartService.getCartItemCount(userId);
        return ResponseEntity.ok(ApiResponse.success(Map.of("total", total, "itemCount", itemCount)));
    }
}
