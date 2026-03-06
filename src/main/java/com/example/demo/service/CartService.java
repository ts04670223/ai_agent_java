package com.example.demo.service;

import com.example.demo.model.*;
import com.example.demo.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Optional;

@Service
public class CartService {

    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final UserRepository userRepository;
    private final ProductRepository productRepository;

    public CartService(CartRepository cartRepository,
            CartItemRepository cartItemRepository,
            UserRepository userRepository,
            ProductRepository productRepository) {
        this.cartRepository = cartRepository;
        this.cartItemRepository = cartItemRepository;
        this.userRepository = userRepository;
        this.productRepository = productRepository;
    }

    /**
     * 取得用戶的購物車
     */
    public Cart getCartByUserId(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("找不到用戶，ID: " + userId));

        return cartRepository.findByUser(user)
                .orElseGet(() -> {
                    Cart newCart = new Cart(user);
                    return cartRepository.save(newCart);
                });
    }

    /**
     * 添加商品到購物車
     */
    @Transactional
    public Cart addItemToCart(Long userId, Long productId, Integer quantity) {
        Cart cart = getCartByUserId(userId);

        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("找不到商品，ID: " + productId));

        // 檢查庫存
        if (product.getStock() < quantity) {
            throw new RuntimeException("庫存不足");
        }

        // 檢查購物車中是否已有此商品
        Optional<CartItem> existingItem = cartItemRepository.findByCartAndProduct(cart, product);

        if (existingItem.isPresent()) {
            // 更新數量
            CartItem item = existingItem.get();
            int newQuantity = item.getQuantity() + quantity;

            if (product.getStock() < newQuantity) {
                throw new RuntimeException("庫存不足");
            }

            item.setQuantity(newQuantity);
            // 更新價格為最新的產品價格
            item.setPrice(product.getPrice());
            cartItemRepository.save(item);
        } else {
            // 新增項目
            CartItem newItem = new CartItem(product, quantity, product.getPrice());
            cart.addItem(newItem);
            cartItemRepository.save(newItem);
        }

        return cartRepository.save(cart);
    }

    /**
     * 更新購物車項目數量
     */
    @Transactional
    public Cart updateCartItemQuantity(Long userId, Integer cartItemId, Integer quantity) {
        Cart cart = getCartByUserId(userId);

        CartItem cartItem = cartItemRepository.findById(cartItemId)
                .orElseThrow(() -> new RuntimeException("找不到購物車項目，ID: " + cartItemId));

        if (!cartItem.getCart().getId().equals(cart.getId())) {
            throw new RuntimeException("購物車項目不屬於此用戶");
        }

        if (quantity <= 0) {
            throw new RuntimeException("數量必須大於 0");
        }

        // 檢查庫存
        if (cartItem.getProduct().getStock() < quantity) {
            throw new RuntimeException("庫存不足");
        }

        cartItem.setQuantity(quantity);
        // 更新價格為最新的產品價格
        cartItem.setPrice(cartItem.getProduct().getPrice());
        cartItemRepository.save(cartItem);

        return cart;
    }

    /**
     * 從購物車移除項目
     */
    @Transactional
    public Cart removeItemFromCart(Long userId, Integer cartItemId) {
        Cart cart = getCartByUserId(userId);

        CartItem cartItem = cartItemRepository.findById(cartItemId)
                .orElseThrow(() -> new RuntimeException("找不到購物車項目，ID: " + cartItemId));

        if (!cartItem.getCart().getId().equals(cart.getId())) {
            throw new RuntimeException("購物車項目不屬於此用戶");
        }

        cart.removeItem(cartItem);
        cartItemRepository.delete(cartItem);

        return cartRepository.save(cart);
    }

    /**
     * 清空購物車
     */
    @Transactional
    public void clearCart(Long userId) {
        Cart cart = getCartByUserId(userId);
        cart.getItems().clear();
        cartRepository.save(cart);
    }

    /**
     * 計算購物車總金額
     */
    public BigDecimal calculateCartTotal(Long userId) {
        Cart cart = getCartByUserId(userId);

        return cart.getItems().stream()
                .map(CartItem::getSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    /**
     * 取得購物車項目數量
     */
    public int getCartItemCount(Long userId) {
        Cart cart = getCartByUserId(userId);
        return cart.getItems().stream()
                .mapToInt(CartItem::getQuantity)
                .sum();
    }
}
