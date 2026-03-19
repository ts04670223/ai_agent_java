package com.example.demo.config;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

import javax.sql.DataSource;

import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;
import jakarta.persistence.EntityManagerFactory;

// @Configuration
// @EnableTransactionManagement
// @EnableJpaRepositories(entityManagerFactoryRef = "secondaryEntityManagerFactory", transactionManagerRef = "secondaryTransactionManager", basePackages = {
//         "com.example.demo.repository" } // 請將第二資料庫的 Repository 移至此套件
// )
public class SecondaryDbConfig {

    // @Bean(name = "secondaryDataSource")
    // @ConfigurationProperties(prefix = "spring.datasource.secondary")
    public DataSource dataSource() {
        return DataSourceBuilder.create().build();
    }

    // @Bean(name = "secondaryEntityManagerFactory")
    public LocalContainerEntityManagerFactoryBean entityManagerFactory(
            EntityManagerFactoryBuilder builder,
            // @Qualifier("secondaryDataSource")
            DataSource dataSource) {

        Map<String, Object> properties = new HashMap<>();
        properties.put("hibernate.hbm2ddl.auto", "update");
        properties.put("hibernate.dialect", "org.hibernate.dialect.MySQLDialect");

        return builder
                .dataSource(dataSource)
                .packages("com.example.demo.model.secondary") // 請將第二資料庫的 Entity 移至此套件
                .persistenceUnit("secondary")
                .properties(properties)
                .build();
    }

    // @Bean(name = "secondaryTransactionManager")
    public PlatformTransactionManager transactionManager(
            // @Qualifier("secondaryEntityManagerFactory")
            EntityManagerFactory entityManagerFactory) {
        return new JpaTransactionManager(Objects.requireNonNull(entityManagerFactory));
    }
}
