# Grafana Dashboard 沒有圖表的解決方案

## 問題診斷

如果 Dashboard 導入後沒有圖表顯示，通常是以下原因：

### 1. 資料源名稱不匹配

**檢查方式**：
1. 訪問 http://localhost:30300
2. 左側選單 > Connections > Data sources
3. 查看 Prometheus 資料源的名稱

**常見問題**：
- JSON 中使用 `"uid": "prometheus"` 但實際名稱可能是 `"Prometheus"` 或其他
- 資料源 UID 與 JSON 中不一致

**解決方案**：
在 Grafana UI 中手動選擇正確的資料源

---

### 2. Prometheus 查詢沒有返回數據

**測試查詢**：
訪問 http://localhost:30090/graph

輸入以下查詢測試：
```promql
# 測試 1: 檢查應用是否被抓取
up{job="kubernetes-pods"}

# 測試 2: 檢查 JVM 指標
jvm_memory_used_bytes{application="Spring Boot Demo"}

# 測試 3: 檢查 HTTP 指標
http_server_requests_seconds_count{application="Spring Boot Demo"}
```

如果沒有數據：
- 檢查 Prometheus targets: http://localhost:30090/targets
- 確認 Pod 有正確的 annotations
- 確認 `/actuator/prometheus` 端點可訪問

---

### 3. 時間範圍問題

**症狀**：Prometheus 有數據，但 Dashboard 顯示"No data"

**原因**：Dashboard 的時間範圍可能沒有涵蓋有數據的時間段

**解決方案**：
1. 點擊右上角的時間選擇器
2. 選擇 "Last 6 hours" 或 "Last 24 hours"
3. 或選擇 "Absolute time range" 自訂範圍

---

## ✅ 手動導入步驟（推薦）

### 步驟 1：訪問 Grafana
```
http://localhost:30300
```

### 步驟 2：登入
- 使用者名稱: `admin`
- 密碼: `NewAdminPassword123`（或您設定的密碼）

### 步驟 3：導入 Dashboard
1. 左側選單 > **Dashboards** > **Import**
2. 點擊 **Upload JSON file**
3. 選擇: `prometheus/dashboards/spring-boot-jvm-fixed.json`
4. **重要**：在 Options 區域，選擇 Prometheus 資料源
5. 點擊 **Import**

### 步驟 4：驗證圖表
- 如果看到 "No data"：
  1. 點擊面板標題 > **Edit**
  2. 檢查 Query 標籤頁中的查詢語句
  3. 點擊 **Run queries** 按鈕測試
  4. 檢查 Data source 是否正確選擇

---

## 🔧 快速測試工具

### 測試 1：檢查 Prometheus 資料源

執行以下命令測試連線：
```bash
vagrant ssh -c "curl -s http://localhost:30300/api/datasources | grep -i prometheus"
```

### 測試 2：檢查 Prometheus 是否有數據

```bash
vagrant ssh -c "curl -s 'http://localhost:30090/api/v1/label/__name__/values' | grep jvm_memory"
```

應該看到類似：
```
"jvm_memory_used_bytes"
"jvm_memory_max_bytes"
...
```

### 測試 3：檢查 Pod metrics 端點

```bash
vagrant ssh -c "kubectl get pods -o wide | grep app-"
# 複製一個 Pod 的 IP，例如 10.244.0.76

vagrant ssh -c "curl -s http://10.244.0.76:8080/actuator/prometheus | head -20"
```

應該看到 Prometheus 格式的指標輸出

---

## 🎯 推薦的導入流程

### 方式 1：從 Grafana 官方導入（最簡單）

1. 訪問 Grafana: http://localhost:30300
2. Dashboards > Import
3. 輸入 Dashboard ID: **4701** (JVM Micrometer)
4. 點擊 Load
5. 選擇 Prometheus 資料源
6. 點擊 Import
7. ✅ 完成！應該能看到圖表

其他推薦 ID：
- **11378** - Spring Boot Statistics
- **12900** - Spring Boot Metrics
- **315** - Kubernetes Cluster

### 方式 2：使用固定的 JSON 檔案

使用 `spring-boot-jvm-fixed.json` 檔案：
- 已經過測試可用
- 包含完整的面板配置
- 查詢語句已優化

---

## 🐛 常見錯誤排除

### 錯誤 1：面板顯示 "Data source not found"

**解決**：
1. 編輯面板（點擊標題 > Edit）
2. 在 Query 標籤的最上方，重新選擇資料源
3. 選擇 "Prometheus"
4. 點擊 Apply

### 錯誤 2：面板顯示 "No data"

**解決**：
1. 確認時間範圍包含有數據的時間
2. 測試查詢：在 Prometheus UI (http://localhost:30090) 執行相同查詢
3. 檢查 application label 是否匹配：`application="Spring Boot Demo"`

### 錯誤 3：面板空白（沒有任何訊息）

**解決**：
1. 檢查瀏覽器 Console (F12) 是否有錯誤
2. 重新整理頁面
3. 清除瀏覽器快取
4. 嘗試使用無痕模式

---

## ✨ 驗證步驟

完成導入後，您應該能看到：

✅ **JVM 堆記憶體使用**面板：顯示兩條線（已使用/最大值）  
✅ **CPU 使用率**面板：顯示儀表板，數值在 0-100%  
✅ **執行緒數量**面板：顯示數字統計  
✅ **GC 次數**面板：顯示數字統計  
✅ **GC 暫停時間**面板：顯示線圖

如果以上都正常顯示，表示 Dashboard 設定成功！

---

## 📞 需要幫助？

如果仍然無法顯示圖表，請提供以下資訊：

1. Prometheus targets 狀態截圖（http://localhost:30090/targets）
2. Grafana 資料源列表截圖
3. 面板錯誤訊息截圖
4. 執行測試命令的輸出

