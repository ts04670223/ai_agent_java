#!/bin/bash
# 套用 Nginx 設定並重新載入
# 用法：bash /vagrant/scripts/nginx/update.sh

# 以 nginx-test6.conf 為唯一設定來源，包含所有路由：
#   /api         → Kong (app-service, read_timeout 330s)
#   /api/ai      → Kong (app-service, read_timeout 330s for LLM)
#   /grafana     → Kong (monitoring, WebSocket upgrade)
#   /prometheus  → Kong (monitoring)
#   /            → frontend (port 3000)

set -e

CONF_SRC="/vagrant/scripts/nginx/nginx-test6.conf"
CONF_DST="/etc/nginx/sites-available/test6.test"

echo "=== 套用 Nginx 設定 ==="
echo "來源: $CONF_SRC"

if [ ! -f "$CONF_SRC" ]; then
  echo "✗ 設定檔不存在: $CONF_SRC"
  exit 1
fi

sudo cp "$CONF_SRC" "$CONF_DST"
sudo ln -sf "$CONF_DST" /etc/nginx/sites-enabled/test6.test
sudo rm -f /etc/nginx/sites-enabled/default

echo "測試設定..."
if sudo nginx -t; then
  sudo systemctl reload nginx
  echo "✓ Nginx 設定已套用並重新載入"
  echo ""
  echo "已配置的路由："
  grep -E "^\s+location" "$CONF_SRC" | sed 's/^\s*/  /'
else
  echo "✗ Nginx 設定有誤，請檢查 $CONF_SRC"
  exit 1
fi
