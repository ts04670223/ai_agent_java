package com.example.demo.config;

import javax.sql.DataSource;

import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.Primary;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;

import jakarta.persistence.EntityManagerFactory;

// @Configuration
// @EnableTransactionManagement
// @EnableJpaRepositories(entityManagerFactoryRef = "primaryEntityManagerFactory", transactionManagerRef = "primaryTransactionManager", basePackages = {
//         "com.example.demo.repository" } // 請將主資料庫的 Repository 移至此套件
// )
public class PrimaryDbConfig {

    @Primary
    // @Bean(name = "primaryDataSource")
    // @ConfigurationProperties(prefix = "spring.datasource.primary")
    public DataSource dataSource() {
        return null; // 此類別當前未啟用（@Configuration 被注解）
    }

    @Primary
    // @Bean(name = "primaryEntityManagerFactory")
    public LocalContainerEntityManagerFactoryBean entityManagerFactory(
            EntityManagerFactoryBuilder builder,
            // @Qualifier("primaryDataSource")
            DataSource dataSource) {
        return null; // 此類別當前未啟用（@Configuration 被注解）
    }

    @Primary
    // @Bean(name = "primaryTransactionManager")
    public PlatformTransactionManager transactionManager(
            // @Qualifier("primaryEntityManagerFactory")
            EntityManagerFactory entityManagerFactory) {
        return null; // 此類別當前未啟用（@Configuration 被注解）
    }
}
