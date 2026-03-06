# 📊 Prometheus 監控系統完整指南

## 📁 目錄結構

```
prometheus/
├── 配置文件/
│   ├── namespace.yaml              # Kubernetes namespace
│   ├── prometheus-rbac.yaml        # RBAC 權限
│   ├── prometheus-config.yaml      # Prometheus 配置
│   ├── prometheus-deployment.yaml  # Prometheus 部署
│   └── grafana-deployment.yaml     # Grafana 部署
├── 管理腳本/
│   ├── prometheus.bat              # Windows 管理工具
│   ├── prometheus.sh               # Linux 管理工具
└── 文檔/
    └── 00-START-HERE.md            # ⭐ 從這裡開始
```

## 🚀 快速開始

### 1. 訪問監控介面

> ⭐ **推薦**: 使用統一域名 http://test6.test/ ([完整指南](../TEST6-UNIFIED-ACCESS.md))

**方式 1: 統一域名 (推薦)**
```
Prometheus: http://test6.test/prometheus
Grafana:    http://test6.test/grafana
```

**方式 2: 直接端口**
```
Prometheus: http://localhost:30090
Grafana:    http://localhost:30300
```

**方式 3: Kong Gateway**
```
Prometheus: http://localhost:30000/prometheus
Grafana:    http://localhost:30000/grafana
```

**Grafana 登入**:
- Username: `admin`
- Password: `NewAdminPassword123`

### 2. 導入 Grafana 儀表板

登入 Grafana 後：
1. 左側菜單 > **Dashboards** > **Import**
2. 輸入 Dashboard ID：
   - **4701** - JVM 監控
   - **11378** - Spring Boot 統計
   - **315** - Kubernetes 集群
3. 選擇 **Prometheus** 數據源

### 3. 管理命令

**Windows**:
```cmd
cd prometheus
prometheus.bat status    # 查看狀態
prometheus.bat logs      # 查看日誌
prometheus.bat restart   # 重啟
```

**Linux/VM**:
```bash
bash /vagrant/prometheus/prometheus.sh status
bash /vagrant/prometheus/prometheus.sh logs
```

## 📊 監控架構

```
┌─────────────────┐
│   Grafana       │ ← 可視化介面 (推薦)
│   :30300        │
└────────┬────────┘
         │
┌────────▼────────┐
│  Prometheus     │ ← 時序資料庫
│   :30090        │
└────────┬────────┘
         │
    ┌────┴────┬──────────────┬──────────┐
    │         │              │          │
┌───▼───┐ ┌──▼──────┐  ┌───▼────┐ ┌──▼──────┐
│ App   │ │ K8s API │  │ Nodes  │ │ Pods    │
│ Pods  │ │ Server  │  │        │ │         │
└───────┘ └─────────┘  └────────┘ └─────────┘
```

## 🎯 常用 PromQL 查詢

### 應用監控
```promql
# JVM 堆內存使用
jvm_memory_used_bytes{area="heap"}

# HTTP 請求率
rate(http_server_requests_seconds_count[5m])

# HTTP 錯誤率
sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) 
/ sum(rate(http_server_requests_seconds_count[5m])) * 100
```

### Kubernetes 監控
```promql
# Pod CPU 使用
rate(container_cpu_usage_seconds_total{namespace="default"}[5m])

# HPA 副本數
kube_deployment_status_replicas{deployment="app"}

# Pod 重啟次數
kube_pod_container_status_restarts_total
```

## 🔧 故障排查

### Grafana 無法訪問
```bash
# 檢查 Pod
kubectl get pods -n monitoring

# 查看日誌
kubectl logs -n monitoring -l app=grafana

# 重啟
kubectl rollout restart deployment/grafana -n monitoring
```

### Prometheus 沒有數據
1. 檢查 Targets: http://localhost:30090/targets
2. 確認 Spring Boot 已重建（包含 Prometheus 依賴）
3. 檢查 Pod 注解是否正確

### Spring Boot 指標不顯示
⚠️ **需要重建應用**

```bash
vagrant ssh
cd /vagrant
mvn clean package -DskipTests
docker build -t spring-boot-app:latest .
kubectl rollout restart deployment/app
```

詳見文檔根目錄的 `prometheus/REBUILD-REQUIRED.md`

## 📚 完整文檔

1. **安裝和配置** - 已完成，服務運行中
2. **PromQL 查詢語法** - 參考 Prometheus 官網
3. **Grafana 儀表板** - 使用 Import 功能導入
4. **告警配置** - 可選，使用 AlertManager

## 🎨 推薦的 Grafana 儀表板

| ID | 名稱 | 說明 |
|----|------|------|
| 4701 | JVM (Micrometer) | JVM 內存、GC、線程 |
| 11378 | Spring Boot Statistics | HTTP 請求、響應時間、錯誤率 |
| 12900 | Spring Boot Metrics | 完整的 Spring Boot 指標 |
| 315 | Kubernetes Cluster | 集群節點、Pod 監控 |
| 8588 | K8s Deployment | Deployment 詳細狀態 |

## 💡 最佳實踐

1. **使用 Grafana** - 比 Prometheus 原生 UI 更專業
2. **組織儀表板** - 按應用/基礎設施分類
3. **設置告警** - 為關鍵指標配置告警
4. **定期備份** - 導出重要儀表板為 JSON
5. **監控 Prometheus** - 確保監控系統本身健康

## 🔗 相關連結

- **Grafana 官網**: https://grafana.com
- **Prometheus 官網**: https://prometheus.io
- **儀表板庫**: https://grafana.com/grafana/dashboards/
- **PromQL 教程**: https://prometheus.io/docs/prometheus/latest/querying/basics/

## ⚙️ 系統資訊

- **Prometheus 版本**: 2.48.0
- **Grafana 版本**: 10.2.2
- **部署方式**: Kubernetes (Native YAML)
- **存儲**: emptyDir (15天保留)
- **資源**: 
  - Prometheus: 250m CPU, 512Mi RAM
  - Grafana: 100m CPU, 128Mi RAM

---

**需要幫助？** 查看 Pod 日誌或檢查服務狀態
