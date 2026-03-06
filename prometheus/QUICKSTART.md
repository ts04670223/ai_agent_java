# Prometheus 快速參考

> ⭐ **完整指南**: 請查看 [00-START-HERE.md](00-START-HERE.md)

## 🎯 當前狀態
✅ Prometheus 和 Grafana 已部署並運行

## 🔗 訪問 Prometheus

### 方式 1: 直接訪問 NodePort
打開瀏覽器訪問:
```
http://localhost:30090
```

或使用:
```
http://test6.test:30090
```

### 方式 2: 使用 Windows 批次檔
```cmd
cd prometheus
prometheus.bat open
```

## 📊 Prometheus Web UI 功能

### 1. Graph (查詢介面)
訪問: `http://localhost:30090/graph`

試試這些查詢:
```promql
# Spring Boot 應用的 JVM 內存使用
jvm_memory_used_bytes{application="Spring Boot Demo"}

# HTTP 請求總數
http_server_requests_seconds_count

# HTTP 請求率 (每秒)
rate(http_server_requests_seconds_count[5m])

# HTTP 請求延遲 (95 百分位)
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m]))

# Pod CPU 使用率
rate(process_cpu_seconds_total{job="spring-boot-app"}[5m])

# HPA 副本數
kube_deployment_status_replicas{deployment="app"}
```

### 2. Targets (監控目標)
訪問: `http://localhost:30090/targets`

查看所有被監控的目標及其狀態:
- ✅ UP: 正常採集指標
- ❌ DOWN: 無法連接或錯誤

當前配置的監控目標:
- `prometheus`: Prometheus 自身
- `kubernetes-apiservers`: Kubernetes API Server
- `kubernetes-nodes`: 集群節點
- `kubernetes-pods`: 所有 Pods (需要有 `prometheus.io/scrape: "true"` 注解)
- `spring-boot-app`: Spring Boot 應用 (通過 /actuator/prometheus)

### 3. Status > Configuration
查看當前的 Prometheus 配置文件

### 4. Status > Targets
查看所有監控目標的健康狀態

## 🔧 管理命令

### Windows (使用 .bat 檔)
```cmd
# 查看狀態
prometheus.bat status

# 查看日誌
prometheus.bat logs

# 重啟
prometheus.bat restart

# 打開 Web UI
prometheus.bat open
```

### Linux/VM 內 (使用 .sh 檔)
```bash
# 查看狀態
bash /vagrant/prometheus/prometheus.sh status

# 查看日誌
bash /vagrant/prometheus/prometheus.sh logs

# 查看監控目標
bash /vagrant/prometheus/prometheus.sh targets

# 重新加載配置
bash /vagrant/prometheus/prometheus.sh reload

# 重啟
bash /vagrant/prometheus/prometheus.sh restart
```

## 📈 驗證 Spring Boot 指標

### 1. 檢查 Actuator 端點
```bash
vagrant ssh -c "curl -s http://localhost:30000/actuator/prometheus | head -20"
```

應該看到類似:
```
# HELP jvm_memory_used_bytes The amount of used memory
# TYPE jvm_memory_used_bytes gauge
jvm_memory_used_bytes{...} 123456789
...
```

### 2. 在 Prometheus UI 中查詢
訪問 `http://localhost:30090/graph`，輸入:
```promql
up{job="spring-boot-app"}
```

如果返回 `1`，表示 Prometheus 成功採集到 Spring Boot 應用的指標。

### 3. 檢查 Target 狀態
訪問 `http://localhost:30090/targets`

搜索 `spring-boot-app`，應該看到:
- State: UP
- Endpoint: 多個 Pod IP

## 🛠️ 故障排除

### 問題 1: Spring Boot 指標沒有顯示

**檢查步驟:**

1. 確認 Pod 有正確的注解:
```bash
vagrant ssh -c "kubectl get pods -l io.kompose.service=app -o yaml | grep -A 5 'prometheus.io'"
```

應該看到:
```yaml
prometheus.io/scrape: "true"
prometheus.io/port: "8080"
prometheus.io/path: "/actuator/prometheus"
```

2. 測試 Actuator 端點:
```bash
vagrant ssh -c "kubectl exec -it \$(kubectl get pod -l io.kompose.service=app -o jsonpath='{.items[0].metadata.name}') -- wget -O- http://localhost:8080/actuator/prometheus"
```

3. 重新部署應用 (如果注解缺失):
```bash
vagrant ssh -c "kubectl apply -f /vagrant/app-deployment.yaml"
vagrant ssh -c "kubectl rollout status deployment/app"
```

### 問題 2: Prometheus 無法訪問

1. 檢查 Pod 狀態:
```bash
vagrant ssh -c "kubectl get pods -n monitoring"
```

2. 檢查服務:
```bash
vagrant ssh -c "kubectl get svc -n monitoring"
```

3. 檢查 NodePort:
```bash
vagrant ssh -c "kubectl get svc prometheus -n monitoring -o jsonpath='{.spec.ports[0].nodePort}'"
```

應該返回 `30090`

### 問題 3: Target 顯示 DOWN

1. 查看詳細錯誤:
訪問 `http://localhost:30090/targets`，查看錯誤訊息

2. 檢查網絡連接:
```bash
vagrant ssh -c "kubectl exec -n monitoring \$(kubectl get pod -n monitoring -l app=prometheus -o jsonpath='{.items[0].metadata.name}') -- wget -O- http://app.default.svc.cluster.local:8080/actuator/prometheus"
```

3. 檢查 RBAC 權限:
```bash
vagrant ssh -c "kubectl auth can-i list pods --as=system:serviceaccount:monitoring:prometheus"
```

## 📚 常用 PromQL 查詢

### JVM 監控
```promql
# JVM 堆內存使用率
jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"} * 100

# GC 時間
rate(jvm_gc_pause_seconds_sum[5m])

# 線程數
jvm_threads_live_threads
```

### HTTP 監控
```promql
# 總請求數
sum(http_server_requests_seconds_count)

# 每秒請求數 (按狀態碼)
sum(rate(http_server_requests_seconds_count[5m])) by (status)

# 平均響應時間
rate(http_server_requests_seconds_sum[5m]) / rate(http_server_requests_seconds_count[5m])

# 錯誤率
sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) / sum(rate(http_server_requests_seconds_count[5m])) * 100
```

### 資源監控
```promql
# CPU 使用率
rate(process_cpu_seconds_total[5m]) * 100

# 內存使用
process_resident_memory_bytes / 1024 / 1024

# 打開的文件描述符
process_open_fds
```

### Kubernetes 監控
```promql
# Pod 數量
kube_deployment_status_replicas{deployment="app"}

# Pod 重啟次數
kube_pod_container_status_restarts_total{namespace="default"}

# Node CPU 使用率
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

## 🎨 下一步: 安裝 Grafana

Grafana 提供更美觀的儀表板和可視化功能。

### 安裝 Grafana
```bash
vagrant ssh -c "kubectl apply -f /vagrant/prometheus/grafana-deployment.yaml"
```

### 訪問 Grafana
```
http://localhost:30300
```

默認帳號:
- Username: `admin`
- Password: `NewAdminPassword123`

### 配置 Prometheus 數據源
1. 登入 Grafana
2. 左側菜單 > Configuration > Data Sources
3. Add data source > Prometheus
4. URL: `http://prometheus.monitoring.svc.cluster.local:9090`
5. Save & Test

### 導入儀表板
訪問 [Grafana Dashboards](https://grafana.com/grafana/dashboards/)

推薦的儀表板:
- **4701**: JVM (Micrometer)
- **11378**: Spring Boot 2.1+ Statistics
- **12900**: Spring Boot Metrics
- **6417**: Kubernetes Cluster Monitoring

## 📝 配置文件位置

- Namespace: `prometheus/namespace.yaml`
- RBAC: `prometheus/prometheus-rbac.yaml`
- ConfigMap: `prometheus/prometheus-config.yaml`
- Deployment: `prometheus/prometheus-deployment.yaml`
- Grafana: `prometheus/grafana-deployment.yaml`
- 管理腳本: `prometheus/prometheus.sh` / `prometheus.bat`

## 🔒 安全建議

1. **生產環境中**，應該:
   - 修改默認密碼
   - 啟用 HTTPS
   - 配置身份驗證 (通過 Ingress + OAuth)
   - 限制網絡訪問 (NetworkPolicy)

2. **數據持久化**:
   當前使用 `emptyDir`，Pod 重啟會丟失數據。
   生產環境應配置 PersistentVolume。

3. **資源限制**:
   根據實際負載調整 CPU/Memory 限制。

## 📞 需要幫助?

查看日誌:
```bash
vagrant ssh -c "kubectl logs -n monitoring -l app=prometheus --tail=100"
```

查看事件:
```bash
vagrant ssh -c "kubectl get events -n monitoring --sort-by='.lastTimestamp'"
```

完整文檔: [prometheus/README.md](README.md)
