#!/bin/bash
# Grafana Dashboard 自動導入腳本

GRAFANA_URL="http://localhost:30300"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="NewAdminPassword123"

echo "🎨 開始導入 Grafana Dashboards..."

# 函數：導入 dashboard
import_dashboard() {
    local DASHBOARD_ID=$1
    local DASHBOARD_NAME=$2
    
    echo "📊 正在導入: $DASHBOARD_NAME (ID: $DASHBOARD_ID)..."
    
    # 從 Grafana.com 下載 dashboard JSON
    DASHBOARD_JSON=$(curl -s "https://grafana.com/api/dashboards/${DASHBOARD_ID}" | jq -r '.json')
    
    if [ -z "$DASHBOARD_JSON" ] || [ "$DASHBOARD_JSON" == "null" ]; then
        echo "❌ 無法下載 Dashboard ID: $DASHBOARD_ID"
        return 1
    fi
    
    # 準備導入請求
    IMPORT_JSON=$(jq -n \
        --argjson dashboard "$DASHBOARD_JSON" \
        '{
            dashboard: $dashboard,
            overwrite: true,
            inputs: [{
                name: "DS_PROMETHEUS",
                type: "datasource",
                pluginId: "prometheus",
                value: "prometheus"
            }]
        }')
    
    # 導入到 Grafana
    RESULT=$(echo "$IMPORT_JSON" | curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
        -d @- \
        "${GRAFANA_URL}/api/dashboards/import")
    
    if echo "$RESULT" | jq -e '.uid' > /dev/null 2>&1; then
        local UID=$(echo "$RESULT" | jq -r '.uid')
        echo "✅ 成功導入: $DASHBOARD_NAME (UID: $UID)"
        echo "   訪問: ${GRAFANA_URL}/d/${UID}"
    else
        echo "❌ 導入失敗: $DASHBOARD_NAME"
        echo "   錯誤: $(echo "$RESULT" | jq -r '.message // .error // "未知錯誤"')"
    fi
    echo ""
}

# 檢查依賴
if ! command -v jq &> /dev/null; then
    echo "❌ 錯誤: 需要安裝 jq 工具"
    echo "   Ubuntu/Debian: sudo apt-get install jq"
    echo "   CentOS/RHEL: sudo yum install jq"
    exit 1
fi

# 檢查 Grafana 是否可訪問
if ! curl -s -f -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" "${GRAFANA_URL}/api/health" > /dev/null; then
    echo "❌ 無法連接到 Grafana: ${GRAFANA_URL}"
    echo "   請確認 Grafana 正在運行"
    exit 1
fi

echo "✅ Grafana 連接成功"
echo ""

# 導入 Spring Boot 相關 Dashboards
import_dashboard "4701"  "JVM (Micrometer)"
import_dashboard "11378" "Spring Boot Statistics"
import_dashboard "12900" "Spring Boot Metrics"
import_dashboard "10280" "Spring Boot 2.1 System Monitor"

# 導入 Kubernetes 相關 Dashboards
import_dashboard "315"   "Kubernetes Cluster Monitoring"
import_dashboard "8588"  "Kubernetes Deployment Statefulset"
import_dashboard "13770" "Kubernetes Pod Monitoring"

# 導入 Prometheus 自身監控
import_dashboard "3662"  "Prometheus 2.0 Stats"

echo "🎉 Dashboard 導入完成！"
echo "📍 訪問 Grafana: ${GRAFANA_URL}"
echo ""
