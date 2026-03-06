package com.example.demo.repository;

import com.example.demo.model.ProductVariant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProductVariantRepository extends JpaRepository<ProductVariant, Long> {
    List<ProductVariant> findByProductIdAndActiveTrue(Long productId);

    List<ProductVariant> findByProductId(Long productId);

    ProductVariant findBySku(String sku);
}