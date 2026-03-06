#!/bin/bash
# App 管理腳本
# 用法：bash /vagrant/scripts/app.sh <logs|rebuild|restart>

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

CMD="${1:-help}"

case "$CMD" in

  logs)
    APP_POD=$(kubectl get pod -l io.kompose.service=app --no-headers | awk '{print $1}' | head -1)
    echo "Pod: $APP_POD"
    kubectl logs "$APP_POD" --tail="${2:-80}" 2>/dev/null
    ;;

  rebuild)
    # 解除 JAR 檔案鎖定並強制重建 Pod（不重新 Maven 編譯）
    # 適用於 JAR 已存在但程序鎖住無法啟動的情況
    JAR=/vagrant/target/spring-boot-demo-0.0.1-SNAPSHOT.jar
    echo "=== 鎖定 JAR 的程序 ==="
    PIDS=$(sudo fuser "$JAR" 2>/dev/null || true)
    if [ -n "$PIDS" ]; then
      echo "PID: $PIDS"
      for pid in $PIDS; do
        echo "終止 PID $pid..."
        sudo kill -9 "$pid" 2>/dev/null || true
      done
      sleep 2
    else
      echo "無程序鎖定 JAR"
    fi
    kubectl delete pod -l io.kompose.service=app --grace-period=0 --force 2>/dev/null || true
    echo "等待 App Pod 重建..."
    sleep 5
    kubectl get pods -l io.kompose.service=app
    ;;

  restart)
    # 完整重啟：停 Pod → Maven Build → 清 Redis → 重啟 Pod → 等待就緒 → 驗證
    set -e
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         App 重啟流程自動化腳本           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo ""

    # 步驟 1：停止 App Pod
    echo -e "${YELLOW}▶ 步驟 1：停止 App Pod（釋放 JAR 鎖定）...${NC}"
    CURRENT_REPLICAS=$(kubectl get deployment app -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
    kubectl scale deployment app --replicas=0
    echo "  等待 Pod 終止中..."
    for i in $(seq 1 40); do
      POD_COUNT=$(kubectl get pods -l io.kompose.service=app --no-headers 2>/dev/null | wc -l)
      if [ "$POD_COUNT" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} App Pod 已停止"; break
      fi
      [ "$i" -eq 40 ] && echo -e "${YELLOW}⚠${NC} Pod 仍在終止中，繼續執行..." || echo "  等待中... ($i/40)"
      sleep 3
    done
    sleep 3

    # 步驟 2：Maven Build
    echo ""
    echo -e "${YELLOW}▶ 步驟 2：Maven Build...${NC}"
    cd /vagrant
    command -v mvn &>/dev/null || { echo -e "${RED}✗${NC} 找不到 mvn 指令"; exit 1; }
    find /vagrant/target -name "*.jar" -exec rm -f {} \; 2>/dev/null || true
    sleep 2
    if mvn clean package -DskipTests -q 2>&1; then
      JAR_PATH=$(find /vagrant/target -name "*.jar" -not -name "*sources*" | head -1)
      echo -e "${GREEN}✓${NC} Build 成功：$JAR_PATH（$(du -sh "$JAR_PATH" | cut -f1)）"
    else
      echo -e "${RED}✗${NC} Build 失敗，恢復副本數並中止"
      kubectl scale deployment app --replicas="$CURRENT_REPLICAS"
      exit 1
    fi

    # 步驟 3：清除 Redis 快取
    echo ""
    echo -e "${YELLOW}▶ 步驟 3：清除 Redis 快取...${NC}"
    REDIS_POD=$(kubectl get pod -l io.kompose.service=redis -o name --no-headers 2>/dev/null | head -1)
    if [ -n "$REDIS_POD" ]; then
      kubectl exec "$REDIS_POD" -- redis-cli FLUSHALL > /dev/null
      echo -e "${GREEN}✓${NC} Redis 快取已清除"
    else
      echo -e "${YELLOW}⚠${NC} 找不到 Redis Pod，跳過清快取"
    fi

    # 步驟 4：重新啟動 App Pod
    echo ""
    echo -e "${YELLOW}▶ 步驟 4：重新啟動 App Pod...${NC}"
    kubectl scale deployment app --replicas="${CURRENT_REPLICAS:-1}"
    echo -e "${GREEN}✓${NC} Deployment 已擴展至 ${CURRENT_REPLICAS:-1} 個副本"

    # 步驟 5：等待 App 就緒
    echo ""
    echo -e "${YELLOW}▶ 步驟 5：等待 App 就緒（最多 6 分鐘）...${NC}"
    MAX_WAIT=360; ELAPSED=0; INTERVAL=10; READY=false
    while [ $ELAPSED -lt $MAX_WAIT ]; do
      RAW=$(kubectl get pods -l io.kompose.service=app \
        -o jsonpath='{.items[*].status.containerStatuses[*].ready}' 2>/dev/null | tr ' ' '\n')
      READY_COUNT=$(echo "$RAW" | grep -c "^true$" 2>/dev/null || echo 0)
      READY_COUNT=${READY_COUNT:-0}
      if [ "$READY_COUNT" -ge 1 ]; then READY=true; break; fi
      STATUS=$(kubectl get pods -l io.kompose.service=app --no-headers 2>/dev/null \
        | awk '{print "READY="$2, "STATUS="$3, "RESTARTS="$4}' | head -1)
      echo "  [${ELAPSED}s/${MAX_WAIT}s] $STATUS（startup probe 持續重試屬正常）"
      sleep $INTERVAL; ELAPSED=$((ELAPSED + INTERVAL))
    done

    if [ "$READY" = true ]; then
      echo -e "${GREEN}✓${NC} App Pod 已就緒（${ELAPSED}秒）"
    else
      echo -e "${RED}✗${NC} App 啟動逾時（${MAX_WAIT}秒）"
      kubectl get pods -l io.kompose.service=app -o wide 2>/dev/null
      kubectl logs -l io.kompose.service=app --tail=50 2>/dev/null
      exit 1
    fi

    # 步驟 6：健康檢查與 API 測試
    echo ""
    echo -e "${YELLOW}▶ 步驟 6：健康檢查與 API 測試...${NC}"
    APP_IP=$(kubectl get svc app -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "")
    if [ -n "$APP_IP" ]; then
      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${APP_IP}:8080/actuator/health" --max-time 10 || echo "000")
      [ "$HTTP_CODE" = "200" ] \
        && echo -e "${GREEN}✓${NC} Actuator Health: HTTP $HTTP_CODE" \
        || echo -e "${YELLOW}⚠${NC} Actuator Health: HTTP $HTTP_CODE"
      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${APP_IP}:8080/api/products" --max-time 10 || echo "000")
      [ "$HTTP_CODE" = "200" ] \
        && echo -e "${GREEN}✓${NC} /api/products: HTTP $HTTP_CODE" \
        || echo -e "${YELLOW}⚠${NC} /api/products: HTTP $HTTP_CODE"
    fi
    KONG_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://192.168.10.10:30000/api/products" --max-time 5 || echo "000")
    [ "$KONG_CODE" = "200" ] \
      && echo -e "${GREEN}✓${NC} Kong → /api/products: HTTP $KONG_CODE" \
      || echo -e "${YELLOW}⚠${NC} Kong → /api/products: HTTP $KONG_CODE"

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           重啟流程完成！                 ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo "  直接存取：http://192.168.10.10:30000/api/products"
    echo "  前端網址：http://test6.test"
    ;;

  *)
    echo "App 管理腳本"
    echo ""
    echo "用法：bash /vagrant/scripts/app.sh <指令> [選項]"
    echo ""
    echo "指令："
    echo "  logs [N]   顯示 App Pod 最近 N 行日誌（預設 80 行）"
    echo "  rebuild    解除 JAR 鎖定並強制重建 Pod（不重新 Maven 編譯）"
    echo "  restart    完整重啟：Maven Build → 清 Redis → 重啟 Pod → 等待就緒"
    ;;
esac
