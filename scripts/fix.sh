#!/bin/bash
# 修復腳本集合
# 用法：bash /vagrant/scripts/fix.sh <flannel|network|mysql|kong|restart>

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

CMD="${1:-help}"

case "$CMD" in

  flannel)
    echo "================================"
    echo "修復 Flannel 網絡插件..."
    echo "================================"

    echo "步驟 1: 刪除現有 Flannel..."
    kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml \
      --ignore-not-found=true

    echo "步驟 2: 清理 CNI 配置..."
    sudo rm -rf /etc/cni/net.d/* /var/lib/cni/ /run/flannel/

    echo "步驟 3: 重啟 containerd..."
    sudo systemctl restart containerd
    sleep 5

    echo "步驟 4: 設置系統參數..."
    sudo modprobe br_netfilter
    sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
    sudo sysctl -w net.ipv4.ip_forward=1

    echo "步驟 5: 重新安裝 Flannel..."
    kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

    echo "步驟 6: 等待 Flannel pods 啟動（最多 150 秒）..."
    sleep 10
    for i in {1..30}; do
      if kubectl get pods -n kube-flannel -o jsonpath='{.items[*].status.phase}' 2>/dev/null | grep -q "Running"; then
        echo "✓ Flannel pods 正在運行"; break
      fi
      echo "等待... ($i/30)"; sleep 5
    done

    echo "步驟 7: 檢查 subnet.env..."
    if [ -f /run/flannel/subnet.env ]; then
      echo "✓ subnet.env 已建立"; cat /run/flannel/subnet.env
    else
      echo "⚠ subnet.env 尚未建立，請稍候再確認"
    fi

    echo "步驟 8: 重建失敗的 App pods..."
    kubectl delete pods -l io.kompose.service=app --grace-period=0 --force 2>/dev/null || true

    echo ""
    echo "=== 修復完成，當前狀態 ==="
    kubectl get pods -n kube-flannel -o wide
    echo ""
    kubectl get pods -l io.kompose.service=app -o wide
    ;;

  network)
    echo "=== App Pod 網路診斷與修復 ==="
    APP_POD=$(kubectl get pod -l io.kompose.service=app --no-headers | awk '{print $1}' | head -1)
    echo "App Pod: $APP_POD"

    echo ""
    echo "--- Pod 網路介面 ---"
    kubectl exec "$APP_POD" -- ip addr 2>/dev/null | grep 'inet ' || echo "ip 不可用"

    echo ""
    echo "--- DNS resolv.conf ---"
    kubectl exec "$APP_POD" -- cat /etc/resolv.conf 2>/dev/null

    echo ""
    echo "--- 測試連線 Ollama (VM:11434) ---"
    curl -s -m 5 http://192.168.10.10:11434/api/tags | head -c 100 || echo "連線失敗"

    echo ""
    echo "=== 修復：重建 App Pod ==="
    kubectl delete pod "$APP_POD" --grace-period=0
    echo "等待新 Pod 啟動..."; sleep 5
    kubectl get pods | grep app
    ;;

  mysql)
    echo "等待 MySQL 準備就緒..."; sleep 10
    echo "修復 springboot 用戶權限..."
    kubectl exec deployment/mysql -- mysql -uroot -prootpassword << 'EOF'
DROP USER IF EXISTS 'springboot'@'localhost';
DROP USER IF EXISTS 'springboot'@'%';
CREATE USER 'springboot'@'%' IDENTIFIED BY 'springboot123';
GRANT ALL PRIVILEGES ON spring_boot_demo.* TO 'springboot'@'%';
FLUSH PRIVILEGES;
SELECT User, Host FROM mysql.user WHERE User='springboot';
EOF
    echo "權限修復完成！"
    kubectl delete pod -l io.kompose.service=app \
      --field-selector=status.phase!=Running 2>/dev/null || true
    ;;

  kong)
    KONG_ADMIN="http://localhost:30003"
    echo "=== Fix Kong app-service Timeout ==="
    echo ""
    echo "1. 列出 Kong Services..."
    ALL_SVC=$(curl -s "$KONG_ADMIN/services")
    echo "$ALL_SVC" | grep -o '"name":"[^"]*"'

    echo ""
    echo "2. 查詢 app-service 當前設定..."
    curl -s "$KONG_ADMIN/services/app-service" \
      | grep -oE '"(read|write|connect)_timeout":[0-9]+' | tr '\n' ' '
    echo ""

    echo "3. PATCH timeout 為 360000ms..."
    PATCH=$(curl -s -X PATCH "$KONG_ADMIN/services/app-service" \
      -H "Content-Type: application/json" \
      -d '{"read_timeout":360000,"write_timeout":360000,"connect_timeout":60000}')
    NEW_READ=$(echo "$PATCH" | grep -o '"read_timeout":[0-9]*' | cut -d: -f2)
    if [ "$NEW_READ" = "360000" ]; then
      echo -e "${GREEN}✓ app-service timeout 已更新${NC}"
    else
      echo "app-service 未找到，嘗試使用第一個 Service ID..."
      SVC_ID=$(echo "$ALL_SVC" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
      curl -s -X PATCH "$KONG_ADMIN/services/$SVC_ID" \
        -H "Content-Type: application/json" \
        -d '{"read_timeout":360000,"write_timeout":360000,"connect_timeout":60000}' \
        | grep -oE '"(read|write|connect)_timeout":[0-9]+'
    fi

    echo ""
    echo "=== 驗證 ==="
    curl -s "$KONG_ADMIN/services" \
      | grep -oE '"name":"[^"]*"|"(read|write|connect)_timeout":[0-9]+'
    ;;

  restart)
    # VM 重啟後一鍵恢復所有服務
    set -e
    echo "╔════════════════════════════════════════════════╗"
    echo "║  Kubernetes 重啟問題自動修復工具              ║"
    echo "╚════════════════════════════════════════════════╝"

    echo ""
    echo "━━━ 步驟 1: 檢查 Flannel ━━━"
    FLANNEL_STATUS=$(kubectl get pods -n kube-flannel \
      -o jsonpath='{.items[*].status.phase}' 2>/dev/null || echo "NotFound")
    if echo "$FLANNEL_STATUS" | grep -q "Running"; then
      echo -e "${GREEN}✓${NC} Flannel 正在運行"
    else
      echo -e "${YELLOW}⚠${NC} Flannel 未就緒，等待啟動..."
      kubectl wait --for=condition=ready pod -l app=flannel \
        -n kube-flannel --timeout=300s || {
        echo "嘗試重新安裝 Flannel..."
        kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml \
          --ignore-not-found=true
        sleep 5
        kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
        kubectl wait --for=condition=ready pod -l app=flannel -n kube-flannel --timeout=300s
      }
    fi
    if [ -f /run/flannel/subnet.env ]; then
      echo -e "${GREEN}✓${NC} subnet.env 存在"
    else
      echo -e "${YELLOW}⚠${NC} subnet.env 缺失，等待 30 秒..."
      sleep 30
    fi

    echo ""
    echo "━━━ 步驟 2: 清理失敗 Pods ━━━"
    kubectl delete pods --field-selector=status.phase=Failed \
      --all-namespaces --grace-period=0 --force 2>/dev/null || true
    kubectl delete pods --field-selector=status.phase=Unknown \
      --all-namespaces --grace-period=0 --force 2>/dev/null || true
    echo -e "${GREEN}✓${NC} 清理完成"

    echo ""
    echo "━━━ 步驟 3: 檢查 Kong 資料庫 ━━━"
    kubectl wait --for=condition=ready pod -l io.kompose.service=kong-database \
      --timeout=300s || { echo -e "${RED}✗ Kong DB 未就緒${NC}"; exit 1; }
    MIGRATION_STATUS=$(kubectl get jobs kong-migrations \
      -o jsonpath='{.status.succeeded}' 2>/dev/null || echo "0")
    if [ "$MIGRATION_STATUS" != "1" ]; then
      echo "重新執行 Kong migrations..."
      kubectl delete job kong-migrations --ignore-not-found=true
      sleep 3
      kubectl apply -f /vagrant/kong/kong-k8s.yaml
      kubectl wait --for=condition=complete job/kong-migrations --timeout=300s
    fi
    echo -e "${GREEN}✓${NC} Kong migrations 已完成"

    echo ""
    echo "━━━ 步驟 4: Kong 就緒 ━━━"
    KONG_STATUS=$(kubectl get pods -l io.kompose.service=kong \
      -o jsonpath='{.items[*].status.phase}' 2>/dev/null || echo "NotFound")
    if ! echo "$KONG_STATUS" | grep -q "Running"; then
      kubectl delete pod -l io.kompose.service=kong --grace-period=0 --force 2>/dev/null || true
      sleep 5
      kubectl apply -f /vagrant/kong/kong-k8s.yaml
    fi
    kubectl wait --for=condition=ready pod -l io.kompose.service=kong \
      --timeout=300s || { echo -e "${RED}✗ Kong 啟動失敗${NC}"; exit 1; }
    echo -e "${GREEN}✓${NC} Kong 已就緒"

    echo ""
    echo "━━━ 步驟 5: Kong 路由 ━━━"
    for i in {1..30}; do
      curl -f -s http://192.168.10.10:8003/ > /dev/null 2>&1 && break || sleep 2
    done
    ROUTES_COUNT=$(curl -s http://192.168.10.10:8003/routes 2>/dev/null \
      | grep -o '"name"' | wc -l)
    if [ "$ROUTES_COUNT" -gt 0 ]; then
      echo -e "${GREEN}✓${NC} Kong 路由已配置 ($ROUTES_COUNT 個)"
    else
      bash /vagrant/scripts/setup.sh kong
      echo -e "${GREEN}✓${NC} Kong 路由配置完成"
    fi

    echo ""
    echo "━━━ 步驟 6: App Pods ━━━"
    APP_RUNNING=$(kubectl get pods -l io.kompose.service=app \
      -o jsonpath='{.items[*].status.phase}' 2>/dev/null | grep -o "Running" | wc -l)
    [ "$APP_RUNNING" -eq 0 ] && kubectl rollout restart deployment/app
    kubectl wait --for=condition=ready pod -l io.kompose.service=app \
      --timeout=600s || echo -e "${YELLOW}⚠${NC} App pods 尚未完全就緒（啟動時間較長屬正常）"

    echo ""
    echo "━━━ 步驟 7: 驗證 ━━━"
    sleep 5
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
      http://192.168.10.10:30000/api/products --max-time 5 || echo "000")
    [ "$HTTP_CODE" = "200" ] \
      && echo -e "${GREEN}✓ API 正常 (HTTP $HTTP_CODE)${NC}" \
      || echo -e "${RED}✗ API 異常 (HTTP $HTTP_CODE)${NC}"

    echo ""
    kubectl get pods --all-namespaces | grep -E "^default|^kube-flannel"
    ;;

  *)
    echo "修復腳本集合"
    echo ""
    echo "用法：bash /vagrant/scripts/fix.sh <指令>"
    echo ""
    echo "指令："
    echo "  flannel  修復 Flannel CNI 網路插件（subnet.env 遺失）"
    echo "  network  診斷並重建 App Pod 網路連線"
    echo "  mysql    修復 MySQL springboot 用戶權限"
    echo "  kong     修復 Kong app-service read/write timeout 為 360s"
    echo "  restart  VM 重啟後一鍵恢復所有服務（Flannel → Kong → App）"
    ;;
esac
