# 🔗 監控系統快速訪問指南

## 通過 Kong 訪問（推薦）

所有服務統一通過 `http://localhost:30000` 或 `http://test6.test` 訪問

> ⭐ **完整統一訪問指南**: [TEST6-UNIFIED-ACCESS.md](TEST6-UNIFIED-ACCESS.md)

## 統一域名訪問

| 服務 | URL |
|------|-----|
| 前端 | http://test6.test/ |
| 後端 API | http://test6.test/api |
| Prometheus | http://test6.test/prometheus |
| Grafana | http://test6.test/grafana |

### 📊 Grafana (專業監控介面)
- **登入頁面**: http://localhost:30000/grafana
- **首頁**: http://localhost:30000/grafana/
- **儀表板**: http://localhost:30000/grafana/dashboards
- **帳號**: admin / NewAdminPassword123

### 📈 Prometheus (時序資料庫)
- **首頁**: http://localhost:30000/prometheus
- **Graph 查詢**: http://localhost:30000/prometheus/graph
- **Targets**: http://localhost:30000/prometheus/targets
- **Alerts**: http://localhost:30000/prometheus/alerts
- **Status**: http://localhost:30000/prometheus/status
- **Configuration**: http://localhost:30000/prometheus/config

### 🚀 Spring Boot 應用
- **商品列表**: http://localhost:30000/api/products
- **購物車**: http://localhost:30000/api/cart/1
- **用戶**: http://localhost:30000/api/users
- **健康檢查**: http://localhost:30000/api/actuator/health
- **Metrics**: http://localhost:30000/api/actuator/metrics

## 直接訪問（備用方式）

如果 Kong 有問題，可以直接訪問服務：

### Grafana
- http://localhost:30300

### Prometheus
- http://localhost:30090

### Spring Boot
- http://localhost:30080

## 🎯 常用操作

### Prometheus 查詢示例

在 http://localhost:30000/prometheus/graph 執行：

```promql
# 查看所有運行的服務
up

# JVM 堆內存使用（需要先重建應用）
jvm_memory_used_bytes{area="heap"}

# HTTP 請求率
rate(http_server_requests_seconds_count[5m])

# Pod CPU 使用
rate(container_cpu_usage_seconds_total{namespace="default"}[5m])

# HPA 副本數
kube_deployment_status_replicas{deployment="app"}
```

### Grafana 導入儀表板

1. 訪問 http://localhost:30000/grafana
2. 登入 (admin/NewAdminPassword123)
3. 左側菜單 > Dashboards > Import
4. 輸入 Dashboard ID：
   - **4701** - JVM 監控
   - **11378** - Spring Boot 統計
   - **315** - Kubernetes 集群

## 🗂️ 路由配置

| 路徑 | 後端服務 | 說明 |
|------|---------|------|
| `/grafana` | grafana.monitoring:3000 | Grafana 監控介面 |
| `/prometheus` | prometheus.monitoring:9090 | Prometheus 時序資料庫 |
| `/api` | app.default:8080 | Spring Boot 應用 API |

## 💡 提示

1. **統一使用 Kong 路由** - 所有服務都通過 `localhost:30000` 訪問
2. **路徑前綴** - 記得加上對應的前綴 (`/grafana`, `/prometheus`, `/api`)
3. **Grafana 更好用** - 建議使用 Grafana 而不是 Prometheus 原生 UI
4. **書籤收藏** - 將常用頁面加入書籤方便訪問

## 🔧 管理命令

### 檢查服務狀態
```bash
vagrant ssh -c "kubectl get pods -n monitoring"
vagrant ssh -c "kubectl get pods | grep app"
vagrant ssh -c "kubectl get svc"
```

### 查看 Kong 路由
```bash
vagrant ssh -c "curl -s http://localhost:30003/routes | grep '\"name\"'"
```

### 重啟服務
```bash
# 重啟 Grafana
vagrant ssh -c "kubectl rollout restart deployment/grafana -n monitoring"

# 重啟 Prometheus
vagrant ssh -c "kubectl rollout restart deployment/prometheus -n monitoring"

# 重啟 Kong
vagrant ssh -c "kubectl rollout restart deployment/kong"
```

## 📚 相關文檔

- [prometheus/GRAFANA-GUIDE.md](GRAFANA-GUIDE.md) - Grafana 使用指南
- [prometheus/QUICKSTART.md](QUICKSTART.md) - Prometheus 快速開始
- [prometheus/README.md](README.md) - 完整技術文檔

---

**快速開始**: 訪問 http://localhost:30000/grafana 開始監控！
