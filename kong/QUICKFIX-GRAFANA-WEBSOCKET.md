# ⚡ Grafana WebSocket 錯誤 - 快速修復指南

## 🎯 問題
訪問 `http://test6.test/grafana` 時出現：
```
WebSocket connection to 'ws://test6.test/grafana/api/live/ws' failed
```

## ✅ 解決方案（3 步驟）

### 步驟 1：連接到 VM

打開 **PowerShell** 或 **CMD**，執行：

```powershell
cd c:\JOHNY\test
vagrant ssh
```

### 步驟 2：在 VM 中執行修復命令

連接成功後（看到 `vagrant@k8s-master:~$` 提示符），**複製貼上**以下完整命令：

```bash
KONG_ADMIN_URL='http://localhost:30003' && \
echo '正在修復 Grafana WebSocket...' && \
curl -i -X DELETE ${KONG_ADMIN_URL}/routes/grafana-route 2>/dev/null && \
echo '' && \
curl -i -X POST ${KONG_ADMIN_URL}/services/grafana/routes \
  --data 'name=grafana-route' \
  --data 'paths[]=/grafana' \
  --data 'strip_path=false' \
  --data 'protocols[]=http' \
  --data 'protocols[]=https' \
  --data 'protocols[]=ws' \
  --data 'protocols[]=wss' && \
echo '' && \
echo '✓ 修復完成！驗證配置：' && \
curl -s ${KONG_ADMIN_URL}/routes/grafana-route | grep -o '"protocols":\[[^]]*\]'
```

### 步驟 3：驗證修復

1. **在瀏覽器中訪問**：`http://test6.test/grafana`

2. **打開開發者工具**（按 `F12`）

3. **檢查 Console 標籤**：
   - ✅ 應該不再看到 WebSocket 錯誤
   - ✅ Network 標籤中 `ws` 連接顯示為成功（Status 101）

## 📋 預期輸出

成功執行後，您應該看到類似以下的輸出：

```
HTTP/1.1 201 Created
...
正在修復 Grafana WebSocket...

✓ 修復完成！驗證配置：
"protocols":["http","https","ws","wss"]
```

## 🔄 替代方法（如果上面不工作）

### 方法 A：分步執行

在 VM 中（`vagrant ssh` 後）逐行執行：

```bash
# 1. 設定變數
KONG_ADMIN_URL='http://localhost:30003'

# 2. 刪除舊路由（如果出錯忽略）
curl -X DELETE ${KONG_ADMIN_URL}/routes/grafana-route

# 3. 創建新路由
curl -X POST ${KONG_ADMIN_URL}/services/grafana/routes \
  --data 'name=grafana-route' \
  --data 'paths[]=/grafana' \
  --data 'strip_path=false' \
  --data 'protocols[]=http' \
  --data 'protocols[]=https' \
  --data 'protocols[]=ws' \
  --data 'protocols[]=wss'

# 4. 驗證
curl ${KONG_ADMIN_URL}/routes/grafana-route
```

### 方法 B：使用預備腳本

```bash
cd /vagrant/kong
chmod +x fix-grafana-websocket.sh
./fix-grafana-websocket.sh
```

## ❓ 疑難排解

### 問題：curl 命令無法連接

**檢查 Kong 狀態：**
```bash
kubectl get pods | grep kong
kubectl get svc kong
```

**如果 Kong 未運行，啟動它：**
```bash
kubectl apply -f /vagrant/kong/kong-k8s.yaml
```

### 問題：grafana-route 不存在

這是正常的！直接執行創建命令（跳過刪除步驟）。

### 問題：修復後仍有 WebSocket 錯誤

1. **清除瀏覽器緩存**：
   - Chrome/Edge: `Ctrl + Shift + Delete`
   - 選擇「快取的圖片和檔案」
   - 點擊「清除資料」

2. **硬性重新整理頁面**：
   - `Ctrl + F5` 或 `Ctrl + Shift + R`

3. **檢查路由配置**：
```bash
curl http://localhost:30003/routes/grafana-route | jq .protocols
```
應該顯示：`["http", "https", "ws", "wss"]`

### 問題：vagrant ssh 失敗

**確認 VM 運行中：**
```powershell
cd c:\JOHNY\test
vagrant status
```

**如果停止了，啟動 VM：**
```powershell
vagrant up
```

## 📚 技術背景

### 為什麼需要這個修復？

Grafana 使用 WebSocket 來實現：
- 🔄 實時儀表板更新
- 📊 動態數據流
- 🔔 即時告警通知
- 👥 多用戶協作

Kong 默認只支持 HTTP/HTTPS，需要明確添加 `ws` 和 `wss` 協議才能正確代理 WebSocket 連接。

### 配置說明

- **protocols**: `["http", "https", "ws", "wss"]` - 支持所有必需協議
- **strip_path**: `false` - 保留 `/grafana` 路徑前綴
- **paths**: `["/grafana"]` - 匹配路由路徑

## 📖 相關文檔

- 完整技術文檔：[GRAFANA-WEBSOCKET-FIX.md](GRAFANA-WEBSOCKET-FIX.md)
- VM 訪問指南：[../docs/VM-ACCESS.md](../docs/VM-ACCESS.md)
- Kong 路由配置：[setup-monitoring-routes.sh](setup-monitoring-routes.sh)

## ✅ 完成清單

- [ ] 已連接到 Vagrant VM (`vagrant ssh`)
- [ ] 已執行修復命令
- [ ] 看到成功的 HTTP 201 響應
- [ ] 驗證顯示包含 ws 和 wss 協議
- [ ] 瀏覽器訪問 `http://test6.test/grafana` 無錯誤
- [ ] 開發者工具中無 WebSocket 錯誤
- [ ] 成功登入 Grafana (admin/NewAdminPassword123)

---

## 🆘 仍需幫助？

如果按照以上步驟操作後問題仍然存在，請執行以下診斷命令並提供輸出：

```bash
# 在 VM 中執行
echo "=== Kong Pod 狀態 ==="
kubectl get pods | grep kong

echo "=== Kong Service ==="
kubectl get svc kong

echo "=== Grafana Route 配置 ==="
curl -s http://localhost:30003/routes/grafana-route

echo "=== Kong 日誌（最後 20 行）==="
kubectl logs -l io.kompose.service=kong --tail=20
```

將輸出分享以獲得進一步協助。
