#!/bin/bash

# 修復 Grafana WebSocket 連接問題
# 更新 Kong 路由以支持 WebSocket 協議

KONG_ADMIN_URL="http://localhost:30003"

echo "================================"
echo "修復 Grafana WebSocket 配置"
echo "================================"

# 1. 刪除現有的 Grafana Route
echo "刪除現有的 grafana-route..."
curl -i -X DELETE ${KONG_ADMIN_URL}/routes/grafana-route

echo ""
echo "--------------------------------"

# 2. 重新創建 Grafana Route（Kong 3.x 不支援 ws/wss protocol，WebSocket 透過 http upgrade 自動處理）
echo "創建 grafana-route (strip_path=false)..."
curl -i -X POST ${KONG_ADMIN_URL}/services/grafana/routes \
  --data 'name=grafana-route' \
  --data 'paths[]=/grafana' \
  --data 'strip_path=false' \
  --data 'protocols[]=http' \
  --data 'protocols[]=https'

echo ""
echo "--------------------------------"

# 3. 驗證配置
echo ""
echo "================================"
echo "驗證 Grafana 路由配置"
echo "================================"

echo ""
echo "Grafana Route 詳細信息："
curl -s ${KONG_ADMIN_URL}/routes/grafana-route | jq '.' 2>/dev/null || curl -s ${KONG_ADMIN_URL}/routes/grafana-route

echo ""
echo "================================"
echo "修復完成！"
echo "================================"
echo ""
echo "請重新測試 WebSocket 連接："
echo "  http://test6.test/grafana"
echo ""
echo "WebSocket 端點應該可以正常工作："
echo "  ws://test6.test/grafana/api/live/ws"
echo ""
