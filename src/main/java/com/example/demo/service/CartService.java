package com.example.demo.service;

import java.math.BigDecimal;
import java.util.Objects;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.demo.exception.BusinessException;
import com.example.demo.exception.ResourceNotFoundException;
import com.example.demo.model.Cart;
import com.example.demo.model.CartItem;
import com.example.demo.model.Product;
import com.example.demo.model.User;
import com.example.demo.repository.CartItemRepository;
import com.example.demo.repository.CartRepository;
import com.example.demo.repository.ProductRepository;
import com.example.demo.repository.UserRepository;

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
        User user = userRepository.findById(Objects.requireNonNull(userId))
                .orElseThrow(() -> new ResourceNotFoundException("用戶", userId));

        return cartRepository.findByUser(user)
                .orElseGet(() -> cartRepository.save(new Cart(user)));
    }

    /**
     * 添加商品到購物車
     */
    @Transactional
    public Cart addItemToCart(Long userId, Long productId, Integer quantity) {
        Cart cart = getCartByUserId(userId);

        Product product = productRepository.findById(Objects.requireNonNull(productId))
                .orElseThrow(() -> new ResourceNotFoundException("商品", productId));

        if (product.getStock() < quantity) {
            throw new BusinessException("庫存不足");
        }

        Optional<CartItem> existingItem = cartItemRepository.findByCartAndProduct(cart, product);

        if (existingItem.isPresent()) {
            CartItem item = existingItem.get();
            int newQuantity = item.getQuantity() + quantity;
            if (product.getStock() < newQuantity) {
                throw new BusinessException("庫存不足");
            }
            item.setQuantity(newQuantity);
            item.setPrice(product.getPrice());
            cartItemRepository.save(item);
        } else {
            CartItem newItem = new CartItem(product, quantity, product.getPrice());
            cart.addItem(newItem);
            cartItemRepository.save(newItem);
        }

        return cartRepository.save(cart);
    }

    /**
     * 更新購物車項目數量（優化 #7：cartItemId 改為 Long）
     */
    @Transactional
    public Cart updateCartItemQuantity(Long userId, Long cartItemId, Integer quantity) {
        Cart cart = getCartByUserId(userId);

        CartItem cartItem = cartItemRepository.findById(Objects.requireNonNull(cartItemId).intValue())
                .orElseThrow(() -> new ResourceNotFoundException("購物車項目", cartItemId));

        if (!cartItem.getCart().getId().equals(cart.getId())) {
            throw new BusinessException("購物車項目不屬於此用戶");
        }

        if (quantity <= 0) {
            throw new BusinessException("數量必須大於 0");
        }

        if (cartItem.getProduct().getStock() < quantity) {
            throw new BusinessException("庫存不足");
        }

        cartItem.setQuantity(quantity);
        cartItem.setPrice(cartItem.getProduct().getPrice());
        cartItemRepository.save(cartItem);

        return cart;
    }

    /**
     * 從購物車移除項目（優化 #7：cartItemId 改為 Long）
     */
    @Transactional
    public Cart removeItemFromCart(Long userId, Long cartItemId) {
        Cart cart = getCartByUserId(userId);

        CartItem cartItem = cartItemRepository.findById(Objects.requireNonNull(cartItemId).intValue())
                .orElseThrow(() -> new ResourceNotFoundException("購物車項目", cartItemId));

        if (!cartItem.getCart().getId().equals(cart.getId())) {
            throw new BusinessException("購物車項目不屬於此用戶");
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
