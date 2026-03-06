package com.example.demo.service;

import com.example.demo.model.Product;
import com.example.demo.repository.ProductRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;

@Service
public class DataInitializationService implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(DataInitializationService.class);

    private final ProductRepository productRepository;

    public DataInitializationService(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    @Override
    public void run(String... args) throws Exception {
        if (productRepository.count() == 0) {
            initializeTestData();
        }
    }

    @Transactional
    private void initializeTestData() {
        List<Product> products = Arrays.asList(
                createProduct("iPhone 15 Pro", "最新的蘋果智慧手機，搽載A17 Pro晶片", "35900.00", 50, "手機"),
                createProduct("MacBook Air M2", "輕小筆電，搽載M2晶片，13吋視網膜顯示器", "36900.00", 30, "筆電"),
                createProduct("AirPods Pro", "主動降噪真無線耳機", "7490.00", 100, "音響"),
                createProduct("iPad Pro 12.9吋", "專業級平板電腦，M2晶片", "33900.00", 25, "平板"),
                createProduct("Apple Watch Series 9", "最新智慧手錶，健康監測功能", "12900.00", 75, "穿戴"),
                createProduct("Magic Keyboard", "無線鍵盤，適用於Mac", "3490.00", 60, "配件"),
                createProduct("Studio Display", "27吋5K顯示器", "49900.00", 15, "顯示器"),
                createProduct("Mac mini M2", "小巧桌上型電腦，M2晶片", "19900.00", 40, "桌機")
        );
        productRepository.saveAll(products);
        logger.info("已初始化 {} 個測試商品", products.size());
    }

    private Product createProduct(String name, String description, String price, int stock, String category) {
        Product product = new Product();
        product.setName(name);
        product.setDescription(description);
        product.setPrice(new BigDecimal(price));
        product.setStock(stock);
        product.setCategory(category);
        product.setActive(true);
        return product;
    }
}