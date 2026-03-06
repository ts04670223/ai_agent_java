# test6.test 統一訪問配置

## 🎯 配置概覽

所有服務現已整合至 **http://test6.test/** 統一入口，通過 Nginx + Kong Gateway 實現路由。

## 🌐 訪問地址

| 服務 | URL | 說明 |
|------|-----|------|
| **前端** | http://test6.test/ | Vite React 應用 (port 3000) |
| **後端 API** | http://test6.test/api | Spring Boot REST API |
| **Prometheus** | http://test6.test/prometheus | 時序資料庫與監控 |
| **Grafana** | http://test6.test/grafana | 監控儀表板 (admin/NewAdminPassword123) |

## 🔧 架構流程

```
瀏覽器
    ↓
test6.test (Nginx:80)
    ↓
    ├─ / ────────────→ Vite (port 3000)
    ├─ /api ─────────→ Kong (port 30000) ─→ Spring Boot (K8s)
    ├─ /prometheus ──→ Kong (port 30000) ─→ Prometheus (K8s)
    └─ /grafana ─────→ Kong (port 30000) ─→ Grafana (K8s)
```

### 詳細說明

1. **前端**: 直接代理到本地 Vite 開發伺服器
2. **後端 API**: 通過 Kong Gateway 路由到 Kubernetes 中的 Spring Boot
3. **Prometheus**: 通過 Kong Gateway 路由到 Kubernetes monitoring namespace
4. **Grafana**: 通過 Kong Gateway 路由到 Kubernetes monitoring namespace

## 📋 前置條件

### Windows hosts 配置

編輯 `C:\Windows\System32\drivers\etc\hosts`，添加：

```
192.168.10.10 test6.test
```

### 確認服務狀態

```bash
# 檢查 Nginx
vagrant ssh -c "sudo systemctl status nginx"

# 檢查 Kong
vagrant ssh -c "kubectl get pods -l app=kong"

# 檢查監控服務
vagrant ssh -c "kubectl get pods -n monitoring"
```

## 🚀 快速驗證

### 1. 檢查前端
```bash
curl http://test6.test/
# 預期: HTTP 200，回傳 HTML
```

### 2. 檢查 API
```bash
curl http://test6.test/api/products
# 預期: HTTP 200，回傳 JSON 商品列表
```

### 3. 檢查 Prometheus
```bash
curl http://test6.test/prometheus/api/v1/status/config
```

### 4. 檢查 Grafana
在瀏覽器訪問：http://test6.test/grafana
- 帳號: admin
- 密碼: NewAdminPassword123

## 📁 配置文件

### Nginx 配置
- **位置**: `/etc/nginx/sites-available/test6.test`
- **更新腳本**: `scripts/update-nginx-monitoring.sh`
- **Windows 工具**: `tools/update-nginx-monitoring.bat`

### Kong 路由配置
- **腳本**: `kong/setup-monitoring-routes.sh`
- **查看路由**: 
  ```bash
  curl http://localhost:30003/routes | jq
  ```

## 🔄 更新配置

如需修改 Nginx 配置：

**Windows**:
```cmd
.\tools\update-nginx-monitoring.bat
```

**Linux/Mac**:
```bash
vagrant ssh -c "bash /vagrant/scripts/update-nginx-monitoring.sh"
```

## 🐛 故障排查

### 問題 1: 無法訪問 test6.test
**解決方案**: 確認 Windows hosts 文件已正確配置

```cmd
notepad C:\Windows\System32\drivers\etc\hosts
```

### 問題 2: Prometheus/Grafana 404
**檢查 Kong 路由**:
```bash
vagrant ssh -c "curl http://localhost:30003/routes | grep -A5 prometheus"
```

**重新配置**:
```bash
vagrant ssh -c "bash /vagrant/kong/setup-monitoring-routes.sh"
```

### 問題 3: Grafana 登入問題
**方案**: 使用直接 NodePort 訪問
```
http://localhost:30300
```

### 問題 4: Nginx 配置錯誤
**恢復備份**:
```bash
vagrant ssh -c "sudo cp /etc/nginx/sites-available/test6.test.backup.* /etc/nginx/sites-available/test6.test && sudo systemctl reload nginx"
```

## 📊 監控指標

### Prometheus 查詢範例

訪問 http://test6.test/prometheus/graph

```promql
# CPU 使用率
rate(process_cpu_seconds_total[1m])

# 記憶體使用
jvm_memory_used_bytes{area="heap"}

# HTTP 請求數
rate(http_server_requests_seconds_count[1m])
```

### Grafana 儀表板

訪問 http://test6.test/grafana

推薦匯入的儀表板：
- **JVM Micrometer**: 4701
- **Spring Boot**: 11378
- **Kubernetes Cluster**: 315

## 🔐 安全注意事項

⚠️ **當前配置僅適用於開發環境**

生產環境建議：
1. 啟用 HTTPS (SSL/TLS)
2. 配置 Kong 認證插件 (JWT, OAuth2)
3. 修改 Grafana 預設密碼
4. 限制 Prometheus 訪問 (IP 白名單)
5. 啟用 Nginx 速率限制

## 📚 相關文檔

- [Kong 配置說明](../kong/README-ROUTES.md)
- [Prometheus 指南](../prometheus/00-START-HERE.md)
- [Grafana 使用指南](../prometheus/GRAFANA-GUIDE.md)
- [故障排查](../docs/TROUBLESHOOTING.md)

## 🎉 總結

✅ 統一入口: http://test6.test/  
✅ 前端 + 後端 + 監控全整合  
✅ Kong Gateway 路由管理  
✅ 簡化訪問流程

現在你可以用一個域名訪問所有服務！
