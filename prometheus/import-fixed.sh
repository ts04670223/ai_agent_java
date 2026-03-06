#!/bin/bash
# 導入修正後的 Dashboard

GRAFANA_URL="http://localhost:30300"
GRAFANA_USER="admin"
GRAFANA_PASS="NewAdminPassword123"

echo "正在導入 Spring Boot JVM Dashboard..."

curl -X POST \
  -H "Content-Type: application/json" \
  -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
  -d @/vagrant/prometheus/dashboards/spring-boot-jvm-fixed.json \
  "${GRAFANA_URL}/api/dashboards/db"

echo ""
echo "完成！請訪問 Grafana 查看: ${GRAFANA_URL}"
