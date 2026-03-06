#!/bin/bash

# Kong 監控路由配置腳本
# 配置 Prometheus 和 Grafana 通過 Kong 訪問

KONG_ADMIN_URL="http://localhost:30003"
PROMETHEUS_URL="http://prometheus.monitoring.svc.cluster.local:9090"
GRAFANA_URL="http://grafana.monitoring.svc.cluster.local:3000"

echo "================================"
echo "配置 Kong 監控路由"
echo "================================"

# 1. 創建 Prometheus Service
echo "創建 Service: prometheus"
curl -i -X POST ${KONG_ADMIN_URL}/services \
  --data name=prometheus \
  --data url=${PROMETHEUS_URL}

echo ""
echo "--------------------------------"

# 2. 創建 Prometheus Route
echo "創建 Route: prometheus-route"
curl -i -X POST ${KONG_ADMIN_URL}/services/prometheus/routes \
  --data 'name=prometheus-route' \
  --data 'paths[]=/prometheus' \
  --data 'strip_path=true' \
  --data 'preserve_host=false'

echo ""
echo "--------------------------------"

# 3. 創建 Grafana Service
echo "創建 Service: grafana"
curl -i -X POST ${KONG_ADMIN_URL}/services \
  --data name=grafana \
  --data url=${GRAFANA_URL}

echo ""
echo "--------------------------------"

# 4. 創建 Grafana Route（支持 WebSocket）
echo "創建 Route: grafana-route"
curl -i -X POST ${KONG_ADMIN_URL}/services/grafana/routes \
  --data 'name=grafana-route' \
  --data 'paths[]=/grafana' \
  --data 'strip_path=false' \
  --data 'protocols[]=http' \
  --data 'protocols[]=https'

echo ""
echo "--------------------------------"

# 5. 為 Grafana 添加 CORS 插件（支持跨域訪問）
echo "為 Grafana 添加 CORS 插件"
curl -i -X POST ${KONG_ADMIN_URL}/services/grafana/plugins \
  --data "name=cors" \
  --data "config.origins=*" \
  --data "config.methods=GET" \
  --data "config.methods=POST" \
  --data "config.methods=PUT" \
  --data "config.methods=DELETE" \
  --data "config.methods=OPTIONS" \
  --data "config.headers=Accept" \
  --data "config.headers=Accept-Version" \
  --data "config.headers=Content-Length" \
  --data "config.headers=Content-MD5" \
  --data "config.headers=Content-Type" \
  --data "config.headers=Date" \
  --data "config.headers=X-Auth-Token" \
  --data "config.credentials=true" \
  --data "config.max_age=3600"

echo ""
echo "--------------------------------"

# 6. 驗證配置
echo ""
echo "================================"
echo "驗證配置"
echo "================================"

echo ""
echo "所有 Services:"
curl -s ${KONG_ADMIN_URL}/services | jq -r '.data[].name' 2>/dev/null || curl -s ${KONG_ADMIN_URL}/services | grep -o '"name":"[^"]*"'

echo ""
echo "所有 Routes:"
curl -s ${KONG_ADMIN_URL}/routes | jq -r '.data[].name' 2>/dev/null || curl -s ${KONG_ADMIN_URL}/routes | grep -o '"name":"[^"]*"'

echo ""
echo "================================"
echo "配置完成！"
echo "================================"
echo ""
echo "訪問地址："
echo "  Prometheus: http://localhost:30000/prometheus"
echo "  Grafana:    http://localhost:30000/grafana"
echo ""
echo "或使用："
echo "  Prometheus: http://test6.test/prometheus"
echo "  Grafana:    http://test6.test/grafana"
echo ""
