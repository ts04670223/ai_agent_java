#!/bin/bash

# Kong 路由配置腳本
# 用於將 API 請求路由到後端 Spring Boot 應用

KONG_ADMIN_URL="http://localhost:30003"
# App 直接在 VM 上以 mvn spring-boot:run 執行，不在 K8s Pod 內
# 從 K8s Pod 內用 Node IP 192.168.10.10 連到 VM 上的 app
APP_SERVICE_URL="http://192.168.10.10:8080"

echo "================================"
echo "配置 Kong 路由"
echo "================================"

# 1. 創建 Service（指向後端應用）
# LLM 推理耗時，connect/write/read timeout 設為 300 秒（預設只有 60 秒會導致 LLM 超時）
echo "創建 Service: spring-boot-app"
curl -i -X POST ${KONG_ADMIN_URL}/services \
  --data name=spring-boot-app \
  --data url=${APP_SERVICE_URL} \
  --data connect_timeout=300000 \
  --data write_timeout=300000 \
  --data read_timeout=300000

echo ""
echo "--------------------------------"

# 2. 創建 Route（將 /api/* 路由到後端）
echo "創建 Route: api-route"
curl -i -X POST ${KONG_ADMIN_URL}/services/spring-boot-app/routes \
  --data 'name=api-route' \
  --data 'paths[]=/api' \
  --data 'strip_path=false'

echo ""
echo "--------------------------------"

# 3. 驗證配置
echo ""
echo "================================"
echo "驗證配置"
echo "================================"

echo ""
echo "Services 列表:"
curl -s ${KONG_ADMIN_URL}/services | grep -o '"name":"[^"]*"' || echo "查詢失敗"

echo ""
echo "Routes 列表:"
curl -s ${KONG_ADMIN_URL}/routes | grep -o '"name":"[^"]*"' || echo "查詢失敗"

echo ""
echo "================================"
echo "配置完成！"
echo "================================"
echo ""
echo "測試指令："
echo "  curl http://localhost:30000/api/products"
echo "  curl http://test6.test/api/cart/2"
echo ""
