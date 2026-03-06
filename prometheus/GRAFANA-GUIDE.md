# 🎨 Grafana 使用指南

> ⭐ **快速開始**: 請先查看 [00-START-HERE.md](00-START-HERE.md)

## 🌐 訪問 Grafana

**直接訪問 (推薦)**: http://localhost:30300

**預設帳號**:
- Username: `admin`
- Password: `NewAdminPassword123`

首次登入後會要求更改密碼（可以選擇跳過）

## 🔗 Prometheus 數據源已自動配置

Grafana 已經自動配置好 Prometheus 作為數據源：
- Name: Prometheus
- URL: http://prometheus.monitoring.svc.cluster.local:9090
- Access: Proxy

## 📊 推薦的儀表板

### 方式 1: 從 Grafana 官方庫導入

1. 點擊左側 **+** > **Import**
2. 輸入以下 Dashboard ID，然後點擊 **Load**

#### Spring Boot 監控
| Dashboard ID | 名稱 | 說明 |
|--------------|------|------|
| **4701** | JVM (Micrometer) | JVM 內存、GC、線程監控 |
| **11378** | Spring Boot Statistics | HTTP 請求、錯誤率、響應時間 |
| **12900** | Spring Boot Metrics | 全面的 Spring Boot 指標 |
| **10280** | Spring Boot 2.1+ | 包含 Tomcat、Cache、DataSource |

#### Kubernetes 監控
| Dashboard ID | 名稱 | 說明 |
|--------------|------|------|
| **315** | Kubernetes Cluster Monitoring | 集群總覽 |
| **8588** | Kubernetes Deployment Statefulset | Deployment 和 Pod 狀態 |
| **13770** | Kubernetes Pod Monitoring | Pod 資源使用詳情 |
| **6417** | Kubernetes Cluster | 節點和容器監控 |

#### Prometheus 本身
| Dashboard ID | 名稱 | 說明 |
|--------------|------|------|
| **3662** | Prometheus 2.0 Stats | Prometheus 性能監控 |

### 方式 2: 自定義儀表板

1. 點擊左側 **+** > **Dashboard**
2. 點擊 **Add new panel**
3. 在 Query 中輸入 PromQL，例如：

```promql
# JVM 堆內存使用
jvm_memory_used_bytes{area="heap"}

# HTTP 請求率
rate(http_server_requests_seconds_count[5m])

# Pod CPU 使用率
rate(container_cpu_usage_seconds_total{namespace="default"}[5m])
```

4. 選擇圖表類型（Time series、Gauge、Bar chart 等）
5. 點擊 **Apply** 保存

## 🎯 快速導入推薦儀表板步驟

### 1. 導入 JVM 監控 (Dashboard 4701)

1. 訪問 http://localhost:30300
2. 登入 (admin/NewAdminPassword123)
3. 左側菜單 > **Dashboards** > **Import**
4. 輸入 Dashboard ID: `4701`
5. 點擊 **Load**
6. 選擇 Data source: **Prometheus**
7. 點擊 **Import**

完成！你現在可以看到 JVM 的：
- Heap/Non-Heap 內存使用
- GC 活動
- 線程數
- CPU 使用率

### 2. 導入 Spring Boot 監控 (Dashboard 11378)

重複上述步驟，使用 Dashboard ID: `11378`

你可以看到：
- HTTP 請求總數和速率
- 響應時間 (P50, P75, P95, P99)
- 錯誤率
- 最慢的端點

### 3. 導入 Kubernetes 集群監控 (Dashboard 315)

使用 Dashboard ID: `315`

查看：
- 節點 CPU/內存使用率
- Pod 數量和狀態
- 網絡 I/O
- 磁盤 I/O

## 🎨 Grafana 功能亮點

### 1. 變量 (Variables)
在儀表板頂部選擇不同的：
- Namespace
- Pod
- Container
- Time Range

### 2. 時間範圍
右上角可以選擇：
- Last 5 minutes
- Last 1 hour
- Last 24 hours
- Last 7 days
- 自定義範圍

### 3. 自動刷新
右上角可以設置自動刷新間隔：
- 5s, 10s, 30s
- 1m, 5m, 15m

### 4. 告警 (Alerts)
可以為任何圖表設置告警規則：
- 當 CPU > 80% 時發送通知
- 當錯誤率 > 5% 時發送通知
- 當記憶體不足時發送通知

### 5. 分享
每個儀表板都可以：
- 分享連結
- 建立快照
- 導出 JSON
- 嵌入到其他網站

## 📈 常用面板配置

### 1. Gauge (儀表盤)
適合顯示當前值：
- CPU 使用率
- 內存使用率
- 錯誤率

### 2. Time Series (時間序列)
適合顯示趨勢：
- 請求速率
- 響應時間
- GC 時間

### 3. Bar Gauge (條形圖)
適合顯示多個項目的比較：
- 各 API 的請求數
- 各 Pod 的 CPU 使用

### 4. Stat (統計)
適合顯示單一數字：
- 總請求數
- 當前副本數
- 錯誤總數

### 5. Table (表格)
適合顯示詳細數據：
- 最慢的請求
- 錯誤列表
- Pod 資源使用排行

## 🛠️ 管理命令

### 查看 Grafana 狀態
```bash
vagrant ssh -c "kubectl get pods -n monitoring -l app=grafana"
```

### 查看 Grafana 日誌
```bash
vagrant ssh -c "kubectl logs -n monitoring -l app=grafana --tail=100"
```

### 重啟 Grafana
```bash
vagrant ssh -c "kubectl rollout restart deployment/grafana -n monitoring"
```

### 刪除 Grafana
```bash
vagrant ssh -c "kubectl delete -f /vagrant/prometheus/grafana-deployment.yaml"
```

## 🔧 進階配置

### 1. 配置 SMTP (郵件告警)

編輯 `prometheus/grafana-deployment.yaml`，添加環境變數：

```yaml
env:
  - name: GF_SMTP_ENABLED
    value: "true"
  - name: GF_SMTP_HOST
    value: "smtp.gmail.com:587"
  - name: GF_SMTP_USER
    value: "your-email@gmail.com"
  - name: GF_SMTP_PASSWORD
    value: "your-password"
  - name: GF_SMTP_FROM_ADDRESS
    value: "grafana@yourdomain.com"
```

### 2. 配置持久化存儲

當前使用 `emptyDir`，重啟會丟失儀表板。

創建 PVC:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: grafana-storage
  namespace: monitoring
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

修改 Deployment 使用 PVC:
```yaml
volumes:
  - name: grafana-storage
    persistentVolumeClaim:
      claimName: grafana-storage
```

### 3. 配置 OAuth (Google/GitHub 登入)

添加環境變數：
```yaml
- name: GF_AUTH_GOOGLE_ENABLED
  value: "true"
- name: GF_AUTH_GOOGLE_CLIENT_ID
  value: "your-client-id"
- name: GF_AUTH_GOOGLE_CLIENT_SECRET
  value: "your-client-secret"
```

## 🎯 最佳實踐

### 1. 組織儀表板
創建資料夾分類：
- **Application**: Spring Boot 應用監控
- **Infrastructure**: Kubernetes 集群監控
- **Database**: MySQL/Redis 監控

### 2. 使用變量
讓儀表板更靈活：
- `$namespace`: 選擇不同的 namespace
- `$pod`: 選擇不同的 pod
- `$interval`: 動態調整時間間隔

### 3. 設置告警
為關鍵指標設置告警：
- CPU > 80% for 5 minutes
- Error rate > 5%
- Memory > 90%
- Pod restart count > 5

### 4. 定期備份
導出重要的儀表板為 JSON 文件備份

### 5. 使用模板
從 Grafana Labs 網站尋找適合的模板，不要從零開始

## 🔍 故障排查

### Grafana 無法訪問
```bash
# 檢查 Pod 狀態
kubectl get pods -n monitoring -l app=grafana

# 查看日誌
kubectl logs -n monitoring -l app=grafana

# 檢查服務
kubectl get svc -n monitoring grafana
```

### 無法連接到 Prometheus
1. 在 Grafana UI: Configuration > Data Sources
2. 點擊 Prometheus
3. 點擊 **Test** 按鈕
4. 如果失敗，檢查 URL 是否正確

### 儀表板沒有數據
1. 確認 Prometheus 有收集到數據
2. 訪問 http://localhost:30090 測試查詢
3. 檢查時間範圍是否正確
4. 確認選擇的變量值是否存在

### 導入儀表板失敗
1. 確認 Dashboard ID 正確
2. 確認已選擇 Prometheus 數據源
3. 某些儀表板可能需要特定的指標，確認應用已暴露這些指標

## 📚 推薦資源

- **Grafana 官方文檔**: https://grafana.com/docs/
- **儀表板庫**: https://grafana.com/grafana/dashboards/
- **Grafana Play (線上體驗)**: https://play.grafana.org/

## 🎨 介面預覽

Grafana 提供的功能：
- 🎨 **深色/淺色主題**
- 📊 **多種圖表類型** (折線、柱狀、圓餅、熱圖...)
- 🔍 **強大的查詢編輯器**
- 📱 **響應式設計** (支援手機)
- 🎯 **drill-down 功能** (點擊圖表深入細節)
- 🔔 **告警整合** (Email, Slack, PagerDuty...)
- 👥 **多用戶管理**
- 🔐 **權限控制**

## 🎉 開始使用

1. 訪問: http://localhost:30300
2. 登入: admin/NewAdminPassword123
3. 導入推薦的儀表板 (4701, 11378, 315)
4. 開始監控！

比起 Prometheus 的原生 UI，Grafana 提供了更直觀、更美觀、更強大的監控體驗！

---

**提示**: 如果還沒重建 Spring Boot 應用，記得先按照 `REBUILD-REQUIRED.md` 重建，這樣才能看到完整的 JVM 和 HTTP 指標。
