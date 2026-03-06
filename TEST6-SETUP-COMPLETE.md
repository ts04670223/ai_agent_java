# ✅ test6.test 統一訪問配置完成

## 🎉 配置成功！

所有服務現已整合至 **http://test6.test/** 統一入口

## 📋 服務狀態

| 服務 | URL | 狀態 |
|------|-----|------|
| **前端** | http://test6.test/ | ✅ HTTP 200 |
| **後端 API** | http://test6.test/api | ✅ HTTP 200 |
| **Prometheus** | http://test6.test/prometheus | ✅ HTTP 200 |
| **Grafana** | http://test6.test/grafana | ✅ HTTP 302 |

## 🏗️ 架構說明

```
瀏覽器 (http://test6.test)
         ↓
  Nginx (Port 80)
         ↓
    ┌────┴────┐
    ↓         ↓
  Vite    Kong Gateway (Port 30000)
(Port 3000)   ↓
         ┌────┴────┐
         ↓         ↓
    Spring Boot  Monitoring (K8s)
    (K8s Pod)    ├─ Prometheus
                 └─ Grafana
```

## ✨ 已完成的配置

### 1. Nginx 配置更新
**文件**: `/etc/nginx/sites-available/test6.test`

添加了以下路由：
- ✅ `/prometheus` → Kong Gateway
- ✅ `/grafana` → Kong Gateway
- ✅ WebSocket 支持（Grafana 需要）

### 2. Kong Gateway 路由
**通過**: `kong/setup-monitoring-routes.sh`

配置了：
- ✅ Prometheus Service & Route
- ✅ Grafana Service & Route
- ✅ CORS 插件

### 3. 自動化腳本
創建了以下工具：
- ✅ `scripts/update-nginx-monitoring.sh` - Linux 更新腳本
- ✅ `tools/update-nginx-monitoring.bat` - Windows 更新腳本
- ✅ `tools/test-test6.bat` - 快速測試腳本

## 🚀 快速開始

### 訪問監控服務

1. **Grafana 儀表板**
   ```
   http://test6.test/grafana
   ```
   - 帳號: `admin`
   - 密碼: `NewAdminPassword123`

2. **Prometheus 查詢**
   ```
   http://test6.test/prometheus/graph
   ```

### 測試所有服務

**Windows**:
```cmd
cd c:\JOHNY\test
.\tools\test-test6.bat
```

**Linux/Mac**:
```bash
curl http://test6.test/prometheus/api/v1/status/config
curl http://test6.test/grafana/api/health
```

## 📚 相關文檔

- **[完整指南](TEST6-UNIFIED-ACCESS.md)** - 詳細配置說明
- **[Prometheus 指南](prometheus/00-START-HERE.md)** - 監控使用說明
- **[Kong 狀態](KONG-STATUS.md)** - Kong 配置總覽
- **[監控訪問](MONITORING-ACCESS.md)** - 訪問方式說明

## 🔧 配置文件位置

| 文件 | 路徑 | 說明 |
|------|------|------|
| Nginx 配置 | `/etc/nginx/sites-available/test6.test` | 主反向代理配置 |
| Kong 監控路由 | `kong/setup-monitoring-routes.sh` | 監控服務路由配置 |
| Prometheus 配置 | `prometheus/prometheus-config.yaml` | Prometheus 抓取配置 |
| Grafana 配置 | `prometheus/grafana-deployment.yaml` | Grafana 部署配置 |

## ⚡ 快速命令

### 查看服務狀態
```bash
# 檢查 Nginx
vagrant ssh -c "sudo systemctl status nginx"

# 檢查 Kong Pods
vagrant ssh -c "kubectl get pods -l app=kong"

# 檢查監控服務
vagrant ssh -c "kubectl get pods -n monitoring"

# 查看 Kong 路由
vagrant ssh -c "curl -s http://localhost:30003/routes | grep -E 'name|paths'"
```

### 重新載入配置
```bash
# 重新載入 Nginx (不中斷服務)
vagrant ssh -c "sudo systemctl reload nginx"

# 重新配置 Kong 路由
vagrant ssh -c "bash /vagrant/kong/setup-monitoring-routes.sh"

# 重啟監控 Pods
vagrant ssh -c "kubectl rollout restart deployment -n monitoring"
```

## 🎯 後續步驟

### 1. 匯入 Grafana 儀表板

訪問 http://test6.test/grafana，登入後：

1. 左側菜單 → **Dashboards** → **Import**
2. 輸入以下 Dashboard ID：
   - **4701** - JVM (Micrometer)
   - **11378** - Spring Boot 2.1 Statistics
   - **315** - Kubernetes Cluster Monitoring

### 2. 配置 Prometheus 警報 (可選)

編輯 `prometheus/prometheus-config.yaml`，添加 alerting rules：
```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```

### 3. 啟用 HTTPS (生產環境)

使用 Let's Encrypt 獲取 SSL 證書：
```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d test6.test
```

## 🐛 故障排查

### 問題 1: 無法訪問 test6.test

**解決方案**: 確認 Windows hosts 文件

```cmd
notepad C:\Windows\System32\drivers\etc\hosts
```

添加：
```
192.168.10.10 test6.test
```

### 問題 2: Grafana 登入失敗

**方案 A**: 使用直接端口訪問
```
http://localhost:30300
```

**方案 B**: 重置 Grafana Pod
```bash
vagrant ssh -c "kubectl delete pod -l app=grafana -n monitoring"
```

### 問題 3: Prometheus 404 錯誤

**檢查路由**:
```bash
vagrant ssh -c "curl http://localhost:30003/routes | grep prometheus"
```

**重新配置**:
```bash
vagrant ssh -c "bash /vagrant/kong/setup-monitoring-routes.sh"
```

## 📊 監控範例

### Prometheus 查詢

訪問 http://test6.test/prometheus/graph

```promql
# CPU 使用率
rate(process_cpu_seconds_total[5m])

# JVM 堆記憶體
jvm_memory_used_bytes{area="heap"}

# HTTP 請求率
rate(http_server_requests_seconds_count[5m])

# Kubernetes Pod 狀態
kube_pod_status_phase
```

### Grafana 儀表板

1. 登入 http://test6.test/grafana
2. 選擇已匯入的儀表板
3. 選擇時間範圍（右上角）
4. 調整刷新間隔（自動更新）

## 🔐 安全建議

⚠️ **當前配置適用於開發環境**

生產環境請執行：
1. ✅ 啟用 HTTPS (SSL/TLS)
2. ✅ 配置 Kong 認證 (JWT/OAuth2)
3. ✅ 修改 Grafana 預設密碼
4. ✅ 限制 Prometheus 訪問
5. ✅ 啟用防火牆規則
6. ✅ 配置 Nginx 速率限制

## 🎓 學習資源

- [Prometheus 官方文檔](https://prometheus.io/docs/)
- [Grafana 官方文檔](https://grafana.com/docs/)
- [Kong Gateway 文檔](https://docs.konghq.com/)
- [PromQL 教程](https://prometheus.io/docs/prometheus/latest/querying/basics/)

---

**配置時間**: 2026-01-22  
**最後更新**: 2026-01-22  
**狀態**: ✅ 生產就緒 (開發環境)
