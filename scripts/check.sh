#!/bin/bash
# 狀態檢查與診斷腳本
# 用法：bash /vagrant/scripts/check.sh <status|network|chat|diag|logs|request|frontend>

CMD="${1:-help}"

case "$CMD" in

  status)
    echo "=== Pods 狀態 ==="
    kubectl get pods
    echo ""
    echo "=== Ollama 狀態 (VM 直接模式) ==="
    curl -s -m 5 http://localhost:11434/api/ps \
      | python3 -c "
import sys, json
d = json.load(sys.stdin)
models = d.get('models', [])
print('載入中的模型:', len(models))
for m in models:
    print(' ', m['name'], '| expires:', m.get('expires_at','?')[:19])
" 2>/dev/null || echo "Ollama 未回應 (sudo systemctl status ollama)"
    echo ""
    echo "=== App 日誌（關鍵訊息）==="
    APP_POD=$(kubectl get pod -l io.kompose.service=app --no-headers 2>/dev/null \
      | awk '{print $1}' | head -1)
    echo "Pod: $APP_POD"
    if [ -n "$APP_POD" ]; then
      kubectl logs "$APP_POD" --tail=60 2>&1 \
        | grep -E "ERROR|WARN|Ollama|ollama|Started|Failed|Exception|warmup|預熱"
    fi
    echo ""
    echo "=== Health + Chat 快速測試 (timeout=30s) ==="
    curl -s -m 5 http://localhost:30000/api/ai/health
    echo ""
    START=$(date +%s)
    curl -s -m 30 -X POST http://localhost:30000/api/ai/chat \
      -H 'Content-Type: application/json' \
      -d '{"message":"hi","history":[],"systemPrompt":null}'
    END=$(date +%s)
    echo ""; echo "耗時: $((END-START))秒"
    ;;

  network)
    echo "================================"
    echo "Kubernetes 網絡診斷報告"
    echo "================================"
    echo ""
    echo "1. Flannel Pods 狀態:"
    kubectl get pods -n kube-flannel -o wide
    echo ""
    echo "2. Flannel 最近日誌:"
    FLANNEL_POD=$(kubectl get pods -n kube-flannel \
      -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    [ -n "$FLANNEL_POD" ] \
      && kubectl logs -n kube-flannel "$FLANNEL_POD" --tail=20 \
      || echo "找不到 Flannel pod"
    echo ""
    echo "3. Flannel subnet.env:"
    [ -f /run/flannel/subnet.env ] \
      && cat /run/flannel/subnet.env \
      || echo "⚠ 不存在: /run/flannel/subnet.env"
    echo ""
    echo "4. CNI 配置目錄:"
    ls -la /etc/cni/net.d/ 2>/dev/null || echo "CNI 目錄不存在"
    echo ""
    echo "5. 節點狀態:"
    kubectl get nodes -o wide
    echo ""
    echo "6. App Pods 狀態:"
    kubectl get pods -l io.kompose.service=app -o wide
    echo ""
    echo "7. 失敗 App Pods 事件:"
    FAILED_PODS=$(kubectl get pods -l io.kompose.service=app \
      --field-selector=status.phase!=Running \
      -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    if [ -n "$FAILED_PODS" ]; then
      for pod in $FAILED_PODS; do
        echo "Pod: $pod"
        kubectl describe pod "$pod" | grep -A10 "Events:"
      done
    else
      echo "沒有失敗的 app pods"
    fi
    echo ""
    echo "8. 系統網絡參數:"
    echo "bridge-nf-call-iptables = $(sysctl net.bridge.bridge-nf-call-iptables 2>/dev/null | awk '{print $3}')"
    echo "ip_forward = $(sysctl net.ipv4.ip_forward 2>/dev/null | awk '{print $3}')"
    ;;

  chat)
    KONG_ADMIN="http://localhost:30003"
    echo "=== Kong Routes (名稱列表) ==="
    curl -s "$KONG_ADMIN/routes" | grep -o '"name":"[^"]*"'
    echo ""
    echo "=== Kong app-service timeout ==="
    curl -s "$KONG_ADMIN/services/app-service" \
      | grep -oE '"(read|write|connect)_timeout":[0-9]+' | tr '\n' ' '
    echo ""
    echo ""
    echo "=== App Pod ==="
    kubectl get pods | grep app
    echo ""
    echo "=== App 日誌（過濾關鍵字）==="
    APP_POD=$(kubectl get pod -l io.kompose.service=app --no-headers 2>/dev/null \
      | grep Running | awk '{print $1}' | head -1)
    kubectl logs "$APP_POD" --tail=30 2>/dev/null \
      | grep -E "預熱|warmup|ERROR|WARN|ollama|model" | head -20
    echo ""
    echo "=== 測試 Chat API (POST, timeout=120s) ==="
    START=$(date +%s)
    RESULT=$(curl -s -m 120 -X POST http://test6.test/api/ai/chat \
      -H "Content-Type: application/json" \
      -d '{"message":"你好，請介紹一下你自己"}' 2>&1)
    END=$(date +%s)
    echo "耗時: $((END-START))秒"
    echo "$RESULT" | head -c 500
    ;;

  diag)
    echo "=== 1. DNS 解析 test6.test ==="
    nslookup test6.test 2>/dev/null || host test6.test 2>/dev/null || echo "DNS lookup failed"
    echo ""
    echo "=== 2. 直接測試 App ClusterIP:8080 ==="
    APP_IP=$(kubectl get service app -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
    echo "App ClusterIP: $APP_IP"
    if [ -n "$APP_IP" ]; then
      curl -s -m 10 "http://${APP_IP}:8080/api/ai/health"
      echo ""
      START=$(date +%s)
      RESULT=$(curl -s -m 90 -X POST "http://${APP_IP}:8080/api/ai/chat" \
        -H "Content-Type: application/json" -d '{"message":"hi"}' 2>&1)
      END=$(date +%s)
      echo "直接耗時: $((END-START))秒 | 結果: ${RESULT:0:300}"
    fi
    echo ""
    echo "=== 3. 透過 Kong (NodePort 30000) ==="
    NODE_IP=$(kubectl get node \
      -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' \
      2>/dev/null || echo "127.0.0.1")
    echo "Node IP: $NODE_IP"
    curl -s -m 10 "http://${NODE_IP}:30000/api/ai/health"; echo ""
    START=$(date +%s)
    RESULT=$(curl -s -m 90 -X POST "http://${NODE_IP}:30000/api/ai/chat" \
      -H "Content-Type: application/json" -d '{"message":"hi"}' 2>&1)
    END=$(date +%s)
    echo "Kong 耗時: $((END-START))秒 | 結果: ${RESULT:0:300}"
    echo ""
    echo "=== 4. App 日誌（最後50行）==="
    APP_POD=$(kubectl get pod -l io.kompose.service=app --no-headers 2>/dev/null \
      | grep Running | awk '{print $1}' | head -1)
    kubectl logs "$APP_POD" --tail=50 2>/dev/null
    ;;

  logs)
    APP_POD=$(kubectl get pod -l io.kompose.service=app --no-headers 2>/dev/null \
      | awk '{print $1}' | head -1)
    echo "Pod: $APP_POD"
    kubectl logs "$APP_POD" --tail="${2:-80}" 2>/dev/null
    ;;

  request)
    echo "=== 模擬 App 對 Ollama 發出完整請求 ==="
    START=$(date +%s)
    RESULT=$(curl -s -m 200 -X POST http://localhost:11434/api/chat \
      -H 'Content-Type: application/json' \
      -d '{
        "model":"qwen2.5:0.5b",
        "messages":[
          {"role":"system","content":"你是購物助手。用繁體中文簡短回答。非購物問題拒絕回答。"},
          {"role":"user","content":"你好"}
        ],
        "stream":false,
        "keep_alive":-1,
        "options":{"num_ctx":128,"num_predict":20,"num_thread":4,"temperature":0.1}
      }')
    END=$(date +%s)
    echo "耗時: $((END-START))秒"
    echo "$RESULT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
content = (d.get('message') or {}).get('content','')[:100]
eval_count = d.get('eval_count', 0)
total_ms = round(d.get('total_duration', 0) / 1e6)
print(f'tokens: {eval_count}, total_ms: {total_ms}')
print(f'content: {content}')
" 2>/dev/null || echo "結果 (raw): ${RESULT:0:200}"
    ;;

  frontend)
    echo "=== 1. 前端服務狀態 ==="
    kubectl get pods | grep -E "frontend|app"
    kubectl get svc  | grep -E "frontend|app"
    echo ""
    echo "=== 2. Nginx /api/ai timeout 設定 ==="
    grep -A8 "location /api/ai" /etc/nginx/sites-available/test6.test 2>/dev/null \
      || echo "找不到 nginx 設定"
    echo ""
    echo "=== 3. 服務連線測試 ==="
    curl -s -m 5 -o /dev/null -w "port 3000: %{http_code}\n" http://localhost:3000/
    curl -s -m 5 -o /dev/null -w "port 80:   %{http_code}\n" http://localhost:80/
    echo ""
    echo "=== 4. App ClusterIP 直連 Chat ==="
    APP_IP=$(kubectl get svc app -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
    echo "App ClusterIP: $APP_IP"
    curl -s -m 30 -X POST "http://${APP_IP}:8080/api/ai/chat" \
      -H "Content-Type: application/json" \
      -d '{"message":"hi","history":[],"systemPrompt":null}' && echo ""
    ;;

  *)
    echo "狀態檢查與診斷腳本"
    echo ""
    echo "用法：bash /vagrant/scripts/check.sh <指令>"
    echo ""
    echo "指令："
    echo "  status        總覽：Pods + Ollama + App 日誌 + Health + Chat 快測"
    echo "  network       K8s 網路診斷（Flannel, CNI, subnet.env, 節點狀態）"
    echo "  chat          Kong 路由 + timeout + Chat API 測試"
    echo "  diag          詳細診斷：DNS → ClusterIP → Kong → 完整路徑"
    echo "  logs [N]      App Pod 日誌（預設 80 行）"
    echo "  request       模擬 App 對 Ollama 發出完整請求（直打 VM:11434）"
    echo "  frontend      前端 + Nginx AI timeout + ClusterIP 直連測試"
    ;;
esac
