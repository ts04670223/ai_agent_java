# Grafana Dashboard JSON 檔案

此目錄包含可直接導入 Grafana 的 Dashboard JSON 配置檔案。

## 📊 可用的 Dashboard

### 1. Spring Boot - JVM 監控 (`spring-boot-jvm.json`)
監控 JVM 相關指標：
- JVM 堆記憶體使用
- JVM 非堆記憶體使用
- GC 暫停時間
- 執行緒數量
- CPU 使用率
- 系統負載

### 2. Spring Boot - HTTP 監控 (`spring-boot-http.json`)
監控 HTTP 請求相關指標：
- HTTP 請求速率
- HTTP 回應時間 (P50/P90/P95/P99)
- 總請求數
- 錯誤率
- QPS (每秒查詢數)
- 各端點請求分布
- HTTP 狀態碼分布

### 3. Kubernetes - Pod 監控 (`kubernetes-pods.json`)
監控 Kubernetes Pod 指標：
- Pod 狀態
- Pod 重啟次數
- Pod CPU 使用率
- Pod 記憶體使用
- Pod 網路接收/傳送

## 🚀 導入方式

### 方式 1：使用批次檔（推薦）
```cmd
cd prometheus
import-json-dashboards.bat
```

### 方式 2：手動導入（透過 UI）
1. 訪問 Grafana: http://localhost:30300
2. 登入 (admin/NewAdminPassword123)
3. 左側選單 > Dashboards > Import
4. 點擊 "Upload JSON file"
5. 選擇對應的 JSON 檔案
6. 選擇 Data source: Prometheus
7. 點擊 Import

### 方式 3：使用 curl 命令
```bash
# Spring Boot JVM 監控
curl -X POST \
  -H "Content-Type: application/json" \
  -u admin:NewAdminPassword123 \
  -d @spring-boot-jvm.json \
  http://localhost:30300/api/dashboards/import

# Spring Boot HTTP 監控
curl -X POST \
  -H "Content-Type: application/json" \
  -u admin:NewAdminPassword123 \
  -d @spring-boot-http.json \
  http://localhost:30300/api/dashboards/import

# Kubernetes Pod 監控
curl -X POST \
  -H "Content-Type: application/json" \
  -u admin:NewAdminPassword123 \
  -d @kubernetes-pods.json \
  http://localhost:30300/api/dashboards/import
```

## 🔧 自訂 Dashboard

如需修改 Dashboard：
1. 在 Grafana UI 中修改 Dashboard
2. 點擊右上角設定圖示 > JSON Model
3. 複製 JSON 內容
4. 更新對應的 JSON 檔案
5. 重新導入

## 📝 注意事項

- 所有 Dashboard 都預設使用 `prometheus` 作為資料源
- 刷新頻率設定為 30 秒
- 時區設定為瀏覽器時區
- `overwrite: true` 表示重新導入會覆蓋現有 Dashboard
