package com.example.demo.dto;

import java.math.BigDecimal;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * 優化 #10：建立商品請求 DTO，避免直接暴露 JPA entity，防止 mass assignment
 */
public class CreateProductRequest {

    @NotBlank(message = "商品名稱不可為空")
    private String name;

    private String description;

    private String shortDescription;

    @NotNull(message = "價格不可為空")
    @DecimalMin(value = "0.0", inclusive = false, message = "價格必須大於 0")
    private BigDecimal price;

    private BigDecimal originalPrice;

    @NotNull(message = "庫存不可為空")
    @Min(value = 0, message = "庫存不可為負數")
    private Integer stock;

    private String brand;

    private String category;

    private String subCategory;

    private Boolean active = true;

    private Boolean featured = false;

    // Getters and Setters
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getShortDescription() { return shortDescription; }
    public void setShortDescription(String shortDescription) { this.shortDescription = shortDescription; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public BigDecimal getOriginalPrice() { return originalPrice; }
    public void setOriginalPrice(BigDecimal originalPrice) { this.originalPrice = originalPrice; }

    public Integer getStock() { return stock; }
    public void setStock(Integer stock) { this.stock = stock; }

    public String getBrand() { return brand; }
    public void setBrand(String brand) { this.brand = brand; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getSubCategory() { return subCategory; }
    public void setSubCategory(String subCategory) { this.subCategory = subCategory; }

    public Boolean getActive() { return active; }
    public void setActive(Boolean active) { this.active = active; }

    public Boolean getFeatured() { return featured; }
    public void setFeatured(Boolean featured) { this.featured = featured; }
}
