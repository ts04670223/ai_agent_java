# Grafana WebSocket 連接錯誤修復指南

## 問題描述

訪問 `http://test6.test/grafana/login` 時出現 WebSocket 連接錯誤：
```
WebSocket connection to 'ws://test6.test/grafana/api/live/ws' failed
```

## 原因分析

Kong API Gateway 的 Grafana 路由配置沒有啟用 WebSocket 協議支持。Grafana 需要使用 WebSocket 來提供實時更新功能，包括：
- 實時儀表板更新
- 實時日誌流
- 告警通知
- 即時協作功能

## 解決方案

### 方法 1：使用自動修復腳本（推薦）

**Windows 系統：**
```cmd
cd c:\JOHNY\test\kong
fix-grafana-websocket.bat
```

**Linux/macOS 系統：**
```bash
cd /c/JOHNY/test/kong
chmod +x fix-grafana-websocket.sh
./fix-grafana-websocket.sh
```

### 方法 2：手動修復

#### 步驟 1：刪除現有路由
```bash
curl -i -X DELETE http://localhost:30003/routes/grafana-route
```

#### 步驟 2：創建支持 WebSocket 的新路由
```bash
curl -i -X POST http://localhost:30003/services/grafana/routes \
  --data 'name=grafana-route' \
  --data 'paths[]=/grafana' \
  --data 'strip_path=false' \
  --data 'protocols[]=http' \
  --data 'protocols[]=https' \
  --data 'protocols[]=ws' \
  --data 'protocols[]=wss'
```

#### 步驟 3：驗證配置
```bash
curl -s http://localhost:30003/routes/grafana-route | jq .
```

應該看到 `protocols` 包含 `["http", "https", "ws", "wss"]`。

### 方法 3：使用 Kubernetes（如果在 K8s 中運行）

如果您在 Kubernetes 中運行，可以使用以下方法：

```bash
# 進入 Kong Pod
kubectl exec -it $(kubectl get pod -l io.kompose.service=kong -o jsonpath='{.items[0].metadata.name}') -- bash

# 在 Pod 內執行修復
curl -i -X DELETE http://localhost:8001/routes/grafana-route
curl -i -X POST http://localhost:8001/services/grafana/routes \
  --data 'name=grafana-route' \
  --data 'paths[]=/grafana' \
  --data 'strip_path=false' \
  --data 'protocols[]=http' \
  --data 'protocols[]=https' \
  --data 'protocols[]=ws' \
  --data 'protocols[]=wss'
```

## 驗證修復

### 1. 檢查路由配置
```bash
curl http://localhost:30003/routes/grafana-route
```

確認輸出包含：
```json
{
  "protocols": ["http", "https", "ws", "wss"],
  "strip_path": false,
  "paths": ["/grafana"]
}
```

### 2. 測試 WebSocket 連接

訪問 Grafana：
```
http://test6.test/grafana
```

打開瀏覽器開發者工具（F12），查看 Network 標籤：
- 應該看到 `ws://test6.test/grafana/api/live/ws` 連接成功
- Status 應該是 `101 Switching Protocols`

### 3. 測試功能

登入 Grafana 後，測試以下功能：
- 儀表板自動刷新
- 實時數據更新
- 不應再看到 WebSocket 錯誤

## 技術說明

### WebSocket 協議支持

Kong 需要明確配置支持以下協議：
- `http` - 標準 HTTP 請求
- `https` - 加密 HTTP 請求
- `ws` - WebSocket 連接
- `wss` - 安全 WebSocket 連接

### 為什麼需要 strip_path=false

Grafana 需要保留完整的路徑 `/grafana`，因為它的配置中設置了 `root_url`。如果設置 `strip_path=true`，Grafana 將無法正確處理請求。

## 常見問題

### Q1: 修復後仍然看到 WebSocket 錯誤
**A:** 清除瀏覽器緩存並重新載入頁面（Ctrl+Shift+R 或 Cmd+Shift+R）。

### Q2: Kong Admin API 無法訪問
**A:** 確認 Kong 服務正在運行：
```bash
kubectl get pods | grep kong
# 或
docker ps | grep kong
```

### Q3: 修改後需要重啟 Kong 嗎？
**A:** 不需要。Kong 的路由配置是動態的，更改會立即生效。

### Q4: 如何永久保存這個配置？
**A:** 配置已更新到 `setup-monitoring-routes.sh`，下次重新部署時會自動使用正確的配置。

## 預防措施

為了防止將來出現類似問題，請確保：

1. **使用更新後的腳本**：使用修改後的 `setup-monitoring-routes.sh`
2. **文檔化配置**：記錄所有需要 WebSocket 支持的服務
3. **測試清單**：部署後測試 WebSocket 連接

## 相關文件

- [kong/setup-monitoring-routes.sh](kong/setup-monitoring-routes.sh) - 更新後的監控路由配置
- [kong/fix-grafana-websocket.sh](kong/fix-grafana-websocket.sh) - WebSocket 修復腳本
- [kong/fix-grafana-websocket.bat](kong/fix-grafana-websocket.bat) - Windows 版修復腳本

## 更新記錄

- **2026-01-23**: 添加 WebSocket 協議支持以修復 Grafana 連接問題

## 參考資料

- [Kong Route Configuration](https://docs.konghq.com/gateway/latest/admin-api/#route-object)
- [Grafana WebSocket Requirements](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/)
- [Kong WebSocket Support](https://docs.konghq.com/gateway/latest/get-started/proxy/)
