#!/bin/bash
# Grafana Dashboard 快速導入腳本（簡化版）

GRAFANA_URL="http://localhost:30300"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="NewAdminPassword123"

echo "🎨 Grafana Dashboard 自動導入工具"
echo "=================================="
echo ""

# 函數：導入 dashboard（使用 Grafana Import API）
import_dashboard_simple() {
    local DASHBOARD_ID=$1
    local DASHBOARD_NAME=$2
    
    echo "📊 導入: $DASHBOARD_NAME (ID: $DASHBOARD_ID)"
    
    # 使用 Grafana 的 dashboard import endpoint
    RESULT=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
        -d "{\"dashboard\":{\"id\":${DASHBOARD_ID}},\"overwrite\":true}" \
        "${GRAFANA_URL}/api/gnet/dashboards/${DASHBOARD_ID}")
    
    # 簡單檢查回應
    if echo "$RESULT" | grep -q '"uid"'; then
        echo "✅ 成功"
    else
        echo "⚠️  請手動導入: 在 Grafana 中輸入 ID ${DASHBOARD_ID}"
    fi
    echo ""
}

echo "正在測試 Grafana 連線..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" "${GRAFANA_URL}/api/health")

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ 無法連接到 Grafana (HTTP $HTTP_CODE)"
    echo "   請確認 Grafana 正在運行: kubectl get pods -n monitoring"
    exit 1
fi

echo "✅ Grafana 連接成功"
echo ""
echo "開始導入推薦的 Dashboards..."
echo ""

# Spring Boot Dashboards
echo "【Spring Boot 監控】"
import_dashboard_simple "4701"  "JVM (Micrometer)"
import_dashboard_simple "11378" "Spring Boot Statistics"
import_dashboard_simple "12900" "Spring Boot Metrics"

echo ""
echo "【Kubernetes 監控】"
import_dashboard_simple "315"   "Kubernetes Cluster"
import_dashboard_simple "8588"  "K8s Deployment"

echo ""
echo "🎉 導入程序完成！"
echo ""
echo "📍 如果自動導入失敗，請手動導入："
echo "   1. 訪問: ${GRAFANA_URL}"
echo "   2. 登入: admin / NewAdminPassword123"
echo "   3. 左側選單 > Dashboards > Import"
echo "   4. 輸入以下 ID 並點擊 Load："
echo "      - 4701  (JVM 監控)"
echo "      - 11378 (Spring Boot 統計)"
echo "      - 12900 (Spring Boot 全面指標)"
echo "      - 315   (Kubernetes 叢集)"
echo "      - 8588  (Kubernetes Deployment)"
echo ""
