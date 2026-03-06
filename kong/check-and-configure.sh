#!/bin/bash

# Kong 健康檢查和自動配置腳本
# 此腳本檢查 Kong 路由配置，如果缺失則自動配置

KONG_ADMIN_URL="http://localhost:30003"

echo "================================"
echo "Kong 配置檢查"
echo "================================"

# 檢查 Kong 是否運行
echo "檢查 Kong 狀態..."
if ! kubectl get pods -l io.kompose.service=kong | grep -q "Running"; then
    echo "✗ Kong 未運行"
    exit 1
fi

echo "✓ Kong 正在運行"

# 等待 Kong Admin API 就緒
echo "等待 Kong Admin API 就緒..."
for i in {1..30}; do
    if curl -s -f "${KONG_ADMIN_URL}/services" > /dev/null 2>&1; then
        echo "✓ Kong Admin API 就緒"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "✗ Kong Admin API 無法連接"
        exit 1
    fi
    sleep 2
done

# 檢查路由配置
echo ""
echo "檢查路由配置..."
SERVICE_COUNT=$(curl -s "${KONG_ADMIN_URL}/services" | grep -o '"name":"spring-boot-app"' | wc -l)
ROUTE_COUNT=$(curl -s "${KONG_ADMIN_URL}/routes" | grep -o '"name":"api-route"' | wc -l)

echo "  Services: ${SERVICE_COUNT}"
echo "  Routes: ${ROUTE_COUNT}"

if [ "$SERVICE_COUNT" -eq "0" ] || [ "$ROUTE_COUNT" -eq "0" ]; then
    echo ""
    echo "⚠ 路由配置缺失，開始自動配置..."
    
    # 刪除舊的配置 Job
    kubectl delete job kong-setup-routes 2>/dev/null || true
    sleep 2
    
    # 創建新的配置 Job
    kubectl apply -f /vagrant/kong/kong-setup-routes-job.yaml
    
    echo ""
    echo "等待配置完成..."
    kubectl wait --for=condition=complete --timeout=60s job/kong-setup-routes
    
    if [ $? -eq 0 ]; then
        echo "✓ 路由配置成功"
    else
        echo "✗ 路由配置失敗，請查看日誌: kubectl logs job/kong-setup-routes"
        exit 1
    fi
else
    echo "✓ 路由配置正常"
fi

# 測試路由
echo ""
echo "測試路由..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:30000/api/products)

if [ "$RESPONSE" = "200" ]; then
    echo "✓ 路由測試成功 (HTTP ${RESPONSE})"
    echo ""
    echo "================================"
    echo "Kong 配置檢查完成 - 一切正常！"
    echo "================================"
else
    echo "⚠ 路由測試警告 (HTTP ${RESPONSE})"
    echo "這可能是因為後端應用尚未就緒"
    echo ""
    echo "================================"
    echo "Kong 配置檢查完成 - 有警告"
    echo "================================"
fi

echo ""
echo "可用的 API 端點："
echo "  http://test6.test/api/products"
echo "  http://test6.test/api/cart/2"
echo ""
