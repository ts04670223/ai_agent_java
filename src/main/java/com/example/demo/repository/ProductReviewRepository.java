package com.example.demo.repository;

import com.example.demo.model.ProductReview;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProductReviewRepository extends JpaRepository<ProductReview, Long> {
    List<ProductReview> findByProductIdAndApprovedTrueOrderByCreatedAtDesc(Long productId);

    List<ProductReview> findByProductId(Long productId);

    List<ProductReview> findByUserId(Long userId);

    @Query("SELECT AVG(r.rating) FROM ProductReview r WHERE r.product.id = :productId AND r.approved = true")
    Double getAverageRatingByProductId(Long productId);

    @Query("SELECT COUNT(r) FROM ProductReview r WHERE r.product.id = :productId AND r.approved = true")
    Long getReviewCountByProductId(Long productId);
}