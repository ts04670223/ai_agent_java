#!/bin/bash
# 測試腳本集合
# 用法：bash /vagrant/scripts/test.sh <chat|kong|ollama|e2e|ai>

CMD="${1:-help}"

case "$CMD" in

  chat)
    PAYLOAD='{"message":"hi","history":[],"systemPrompt":null}'
    echo "=== 1. Streaming SSE (/api/ai/chat/stream) — 直打 App:8080 ==="
    echo "   （第一個 token 約 10-15 秒即顯示）"
    START=$(date +%s)
    curl -s -m 120 -N -X POST http://localhost:8080/api/ai/chat/stream \
      -H 'Content-Type: application/json' -d "$PAYLOAD"
    END=$(date +%s)
    echo ""; echo "Streaming 耗時: $((END-START))秒"
    echo ""
    echo "=== 2. 同步 (/api/ai/chat) — 直打 App:8080 ==="
    START=$(date +%s)
    curl -s -m 120 -X POST http://localhost:8080/api/ai/chat \
      -H 'Content-Type: application/json' -d "$PAYLOAD"
    END=$(date +%s)
    echo ""; echo "同步耗時: $((END-START))秒"
    echo ""
    echo "=== 3. 同步透過 Kong (port 30000) ==="
    START=$(date +%s)
    curl -s -m 120 -X POST http://localhost:30000/api/ai/chat \
      -H 'Content-Type: application/json' -d "$PAYLOAD"
    END=$(date +%s)
    echo ""; echo "Kong 耗時: $((END-START))秒"
    ;;

  kong)
    echo "========================================"
    echo "Kong Gateway 驗證"
    echo "========================================"
    GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
    echo ""
    echo "1. Kong Proxy (port 8000):"
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 2>/dev/null)
    [ "$STATUS" = "404" ] \
      && echo -e "${GREEN}✓ Kong Proxy 正常 (404=無預設路由)${NC}" \
      || echo -e "${RED}✗ Kong Proxy 未回應 (HTTP $STATUS)${NC}"
    echo ""
    echo "2. Kong Admin API (port 8003):"
    if curl -s http://localhost:8003 > /dev/null 2>&1; then
      KONG_VERSION=$(curl -s http://localhost:8003 \
        | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
      echo -e "${GREEN}✓ Kong Admin API 正常 (版本: $KONG_VERSION)${NC}"
    else
      echo -e "${RED}✗ Kong Admin API 未回應${NC}"; exit 1
    fi
    echo ""
    echo "3. Services / Routes / Plugins:"
    curl -s http://localhost:8003/services \
      | grep -o '"name":"[^"]*"' | cut -d'"' -f4 \
      | while read -r s; do echo -e "  ${GREEN}✓${NC} service: $s"; done
    curl -s http://localhost:8003/routes \
      | grep -o '"name":"[^"]*"' | cut -d'"' -f4 \
      | while read -r r; do echo -e "  ${GREEN}✓${NC} route: $r"; done
    curl -s http://localhost:8003/plugins \
      | grep -o '"name":"[^"]*"' | cut -d'"' -f4 \
      | while read -r p; do echo -e "  ${GREEN}✓${NC} plugin: $p"; done
    echo ""
    echo "4. 路由測試 (Host: test6.test):"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Host: test6.test" http://localhost:8000/api 2>&1)
    echo "HTTP $RESPONSE"
    echo "========================================"
    ;;

  ollama)
    echo "=== Ollama 服務狀態 ==="
    systemctl is-active ollama 2>/dev/null \
      && echo "ollama service: active" \
      || echo "ollama service: inactive"
    echo ""
    echo "=== 1. /api/chat (num_predict=5, 快速測試) ==="
    START=$(date +%s)
    curl -s -m 60 -X POST http://localhost:11434/api/chat \
      -H 'Content-Type: application/json' \
      -d '{
        "model":"qwen2.5:0.5b",
        "messages":[
          {"role":"system","content":"簡短回答"},
          {"role":"user","content":"hi"}
        ],
        "stream":false,
        "options":{"num_predict":5,"num_ctx":128,"num_thread":4}
      }'
    END=$(date +%s)
    echo ""; echo "耗時: $((END-START))秒"
    echo ""
    echo "=== 2. /api/generate (直接) ==="
    START=$(date +%s)
    RESULT=$(curl -s -m 60 -X POST http://localhost:11434/api/generate \
      -H 'Content-Type: application/json' \
      -d '{"model":"qwen2.5:0.5b","prompt":"hi","stream":false,"options":{"num_predict":5}}')
    END=$(date +%s)
    echo "$RESULT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('response:', d.get('response','')[:100])
" 2>/dev/null || echo "RAW: ${RESULT:0:200}"
    echo "耗時: $((END-START))秒"
    echo ""
    echo "=== 3. Spring Boot /api/ai/chat ==="
    START=$(date +%s)
    curl -s -m 120 -X POST http://localhost:8080/api/ai/chat \
      -H 'Content-Type: application/json' -d '{"message":"hi"}'
    END=$(date +%s)
    echo ""; echo "耗時: $((END-START))秒"
    ;;

  e2e)
    echo "=== E2E 端到端測試 ==="
    echo ""
    echo "---- 1. Ollama 預熱 (keep_alive=-1) ----"
    START=$(date +%s)
    curl -s -m 120 -X POST http://localhost:11434/api/chat \
      -H 'Content-Type: application/json' \
      -d '{
        "model":"qwen2.5:0.5b",
        "messages":[{"role":"user","content":"hi"}],
        "stream":false,
        "keep_alive":-1,
        "options":{"num_ctx":128,"num_predict":1}
      }' > /dev/null
    END=$(date +%s)
    echo "預熱耗時: $((END-START))秒"
    echo ""
    echo "---- 2. App Health ----"
    curl -s -m 5 http://localhost:30000/api/ai/health; echo ""
    echo ""
    echo "---- 3. Ollama 直接推理 ----"
    START=$(date +%s)
    RESULT=$(curl -s -m 120 -X POST http://localhost:11434/api/chat \
      -H 'Content-Type: application/json' \
      -d '{
        "model":"qwen2.5:0.5b",
        "messages":[{"role":"user","content":"你好"}],
        "stream":false,
        "options":{"num_ctx":128,"num_predict":20}
      }')
    END=$(date +%s)
    echo "耗時: $((END-START))秒"
    echo "$RESULT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('tokens:', d.get('eval_count',0), '| content:', (d.get('message') or {}).get('content','')[:60])
" 2>/dev/null || echo "RAW: ${RESULT:0:200}"
    echo ""
    echo "---- 4. App Chat via Kong ----"
    START=$(date +%s)
    RESULT=$(curl -s -m 270 -X POST http://localhost:30000/api/ai/chat \
      -H 'Content-Type: application/json' \
      -d '{"message":"你好","history":[],"systemPrompt":null}')
    END=$(date +%s)
    echo "耗時: $((END-START))秒"
    echo "$RESULT"
    ;;

  ai)
    echo "=== AI 完整路徑測試：瀏覽器 → nginx → Kong → App → Ollama ==="
    echo ""
    echo "---- 測試 1: Kong NodePort (192.168.10.10:30000) ----"
    START=$(date +%s)
    curl -s -m 120 -X POST "http://192.168.10.10:30000/api/ai/chat" \
      -H "Content-Type: application/json" \
      -d '{"message":"hi","history":[],"systemPrompt":null}' \
      -w "\n[HTTP:%{http_code}][TIME:%{time_total}s]"
    echo ""; echo "耗時: $(($(date +%s)-START))秒"
    echo ""
    echo "---- 測試 2: 攜帶無效 Token（驗證 JWT 邊界）----"
    curl -s -m 30 -X POST "http://192.168.10.10:30000/api/ai/chat" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer invalid_token" \
      -d '{"message":"hi","history":[],"systemPrompt":null}' \
      -w "\n[HTTP:%{http_code}]"
    echo ""
    echo ""
    echo "---- 測試 3: 空訊息（@NotBlank 驗證）----"
    curl -s -m 10 -X POST "http://192.168.10.10:30000/api/ai/chat" \
      -H "Content-Type: application/json" \
      -d '{"message":""}' \
      -w "\n[HTTP:%{http_code}]"
    echo ""
    echo ""
    echo "---- App 最後 10 行日誌 ----"
    APP_POD=$(kubectl get pod -l io.kompose.service=app --no-headers 2>/dev/null \
      | grep Running | awk '{print $1}' | head -1)
    kubectl logs "$APP_POD" --tail=10 2>/dev/null \
      | grep -v "^Hibernate"
    ;;

  *)
    echo "測試腳本集合"
    echo ""
    echo "用法：bash /vagrant/scripts/test.sh <指令>"
    echo ""
    echo "指令："
    echo "  chat    Chat API 全路徑測試（Streaming SSE + 同步 + 透過 Kong）"
    echo "  kong    Kong Gateway 健康驗證（Services / Routes / Plugins）"
    echo "  ollama  Ollama 直連測試（/api/chat + /api/generate + Spring Boot）"
    echo "  e2e     端到端測試（Ollama 預熱 → 直接推理 → 透過 Kong）"
    echo "  ai      完整 AI 路徑測試（Kong + JWT 驗證 + 空訊息驗證）"
    ;;
esac
