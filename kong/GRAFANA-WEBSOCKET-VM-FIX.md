# Grafana WebSocket 修復指南（Vagrant VM 版本）

## 快速修復步驟

### 步驟 1：連接到 VM

在 Windows 主機上打開 PowerShell 或 CMD：

```powershell
cd c:\JOHNY\test
vagrant ssh
```

### 步驟 2：在 VM 中執行修復腳本

連接到 VM 後，執行以下命令：

```bash
# 方法 1：使用已準備好的修復腳本
cd /vagrant/kong
chmod +x fix-grafana-websocket.sh
./fix-grafana-websocket.sh
```

或者手動執行（方法 2）：

```bash
# 設定 Kong Admin URL
KONG_ADMIN_URL="http://localhost:30003"

# 刪除現有路由
curl -i -X DELETE ${KONG_ADMIN_URL}/routes/grafana-route

# 創建支持 WebSocket 的新路由
curl -i -X POST ${KONG_ADMIN_URL}/services/grafana/routes \
  --data 'name=grafana-route' \
  --data 'paths[]=/grafana' \
  --data 'strip_path=false' \
  --data 'protocols[]=http' \
  --data 'protocols[]=https' \
  --data 'protocols[]=ws' \
  --data 'protocols[]=wss'

# 驗證配置
curl -s ${KONG_ADMIN_URL}/routes/grafana-route | jq .
```

### 步驟 3：驗證修復

1. **檢查路由配置**：
```bash
curl http://localhost:30003/routes/grafana-route
```

應該看到包含 `"protocols":["http","https","ws","wss"]` 的輸出。

2. **測試 WebSocket 連接**：

在 Windows 主機上打開瀏覽器，訪問：
```
http://test6.test/grafana
```

打開瀏覽器開發者工具（F12），查看 Console 標籤，應該不再看到 WebSocket 錯誤。

## 替代方法：使用 Kubernetes 命令

如果您在 K8s 中部署 Kong，可以這樣做：

```bash
# 在 VM 中執行
cd /vagrant

# 進入 Kong Pod
kubectl exec -it $(kubectl get pod -l io.kompose.service=kong -o jsonpath='{.items[0].metadata.name}') -- bash

# 在 Kong Pod 中執行修復
curl -i -X DELETE http://localhost:8001/routes/grafana-route

curl -i -X POST http://localhost:8001/services/grafana/routes \
  --data 'name=grafana-route' \
  --data 'paths[]=/grafana' \
  --data 'strip_path=false' \
  --data 'protocols[]=http' \
  --data 'protocols[]=https' \
  --data 'protocols[]=ws' \
  --data 'protocols[]=wss'

# 退出 Pod
exit
```

## 完整的手動修復命令（複製貼上版）

在 VM 中執行以下完整命令：

```bash
# 一鍵修復命令
KONG_ADMIN_URL="http://localhost:30003"

echo "刪除現有 grafana-route..."
curl -i -X DELETE ${KONG_ADMIN_URL}/routes/grafana-route

echo ""
echo "創建支持 WebSocket 的新路由..."
curl -i -X POST ${KONG_ADMIN_URL}/services/grafana/routes \
  --data 'name=grafana-route' \
  --data 'paths[]=/grafana' \
  --data 'strip_path=false' \
  --data 'protocols[]=http' \
  --data 'protocols[]=https' \
  --data 'protocols[]=ws' \
  --data 'protocols[]=wss'

echo ""
echo "驗證配置..."
curl -s ${KONG_ADMIN_URL}/routes/grafana-route | jq -r '.protocols[]'

echo ""
echo "修復完成！請在瀏覽器中測試 http://test6.test/grafana"
```

## 驗證清單

- [ ] 登入到 Vagrant VM (`vagrant ssh`)
- [ ] 執行修復腳本或手動命令
- [ ] 看到成功的 HTTP 回應（200 或 201）
- [ ] 驗證命令顯示包含 ws 和 wss 協議
- [ ] 在瀏覽器中訪問 `http://test6.test/grafana`
- [ ] 打開開發者工具，確認沒有 WebSocket 錯誤
- [ ] 登入 Grafana（admin/NewAdminPassword123）
- [ ] 查看儀表板，確認實時更新正常

## 常見問題

### Q: 找不到 grafana-route
**A:** 路由可能還不存在，直接執行創建命令即可：
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

### Q: Kong Admin API 無法連接
**A:** 檢查 Kong 服務狀態：
```bash
# 如果使用 Kubernetes
kubectl get pods | grep kong
kubectl get svc kong

# 如果使用 Docker
docker ps | grep kong
```

### Q: 修復後仍有錯誤
**A:** 
1. 清除瀏覽器緩存（Ctrl+Shift+Delete）
2. 重新載入頁面（Ctrl+F5）
3. 檢查 Kong 日誌：
```bash
kubectl logs -l io.kompose.service=kong --tail=50
```

## 技術說明

### 為什麼需要 WebSocket 支持？

Grafana 使用 WebSocket 來提供：
- **實時儀表板更新**：自動刷新圖表和數據
- **即時告警**：實時推送告警通知
- **協作功能**：多用戶同時查看時的數據同步
- **日誌流**：實時日誌查看功能

### Kong 協議配置

- `http` / `https`：處理標準的 HTTP 請求
- `ws` / `wss`：處理 WebSocket 升級請求

沒有這些協議配置，Kong 會拒絕 WebSocket 握手請求。

### 路徑處理

- `strip_path=false`：保留 `/grafana` 前綴
- 這確保 Grafana 能正確識別請求路徑並與其配置的 `root_url` 匹配

## 相關文件

- [kong/GRAFANA-WEBSOCKET-FIX.md](GRAFANA-WEBSOCKET-FIX.md) - 完整技術文檔
- [kong/setup-monitoring-routes.sh](setup-monitoring-routes.sh) - 更新後的配置腳本
- [docs/VM-ACCESS.md](../docs/VM-ACCESS.md) - VM 訪問指南

## 需要幫助？

如果問題仍然存在，請提供以下信息：
1. Kong 服務狀態：`kubectl get pods | grep kong`
2. 路由配置：`curl http://localhost:30003/routes/grafana-route`
3. Kong 日誌：`kubectl logs -l io.kompose.service=kong --tail=100`
4. 瀏覽器控制台的完整錯誤信息
