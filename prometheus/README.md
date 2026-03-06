# Prometheus 技術文檔

> ⭐ **快速開始**: 請先查看 [00-START-HERE.md](00-START-HERE.md)

## 概述
Prometheus 是一個開源的時序資料庫和監控系統，專為 Kubernetes 環境設計。

## 架構組件
- **Prometheus Server**: 主要的監控服務器，收集和存儲時間序列數據
- **ConfigMap**: 包含 Prometheus 配置文件
- **RBAC**: 服務帳號和權限配置，允許 Prometheus 發現 Kubernetes 資源
- **Service**: NodePort 服務，通過端口 30090 訪問

## 監控目標
1. **Kubernetes 集群組件**
   - API Server
   - Nodes
   - Pods
   - Services

2. **Spring Boot 應用**
   - 通過 `/actuator/prometheus` 端點收集指標
   - 自動發現標記為 `app` 的服務

3. **Prometheus 自身**
   - 監控 Prometheus 本身的性能

## 安裝步驟

### 1. 部署 Prometheus
```bash
# 創建 namespace
kubectl apply -f prometheus/namespace.yaml

# 部署 RBAC 權限
kubectl apply -f prometheus/prometheus-rbac.yaml

# 部署配置文件
kubectl apply -f prometheus/prometheus-config.yaml

# 部署 Prometheus
kubectl apply -f prometheus/prometheus-deployment.yaml
```

### 2. 驗證安裝
```bash
# 檢查 pod 狀態
kubectl get pods -n monitoring

# 檢查服務
kubectl get svc -n monitoring

# 查看日誌
kubectl logs -n monitoring -l app=prometheus --tail=50
```

## 訪問 Prometheus

### 通過 NodePort (推薦)
```
http://localhost:30090
```
或
```
http://test6.test:30090
```

### 通過 Port-Forward
```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```
然後訪問 `http://localhost:9090`

## Spring Boot 應用集成

### 1. 添加依賴
在 `pom.xml` 中添加：
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

### 2. 配置 Actuator
在 `application.properties` 或 `application.yml` 中：
```properties
management.endpoints.web.exposure.include=health,info,prometheus,metrics
management.endpoint.prometheus.enabled=true
management.metrics.export.prometheus.enabled=true
```

### 3. 添加 Pod 注解
在 `app-deployment.yaml` 中添加注解：
```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/actuator/prometheus"
```

## 常用查詢 (PromQL)

### 應用指標
```promql
# JVM 內存使用率
jvm_memory_used_bytes{namespace="default"}

# HTTP 請求率
rate(http_server_requests_seconds_count[5m])

# HTTP 請求延遲
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m]))

# CPU 使用率
rate(process_cpu_seconds_total[5m])
```

### Kubernetes 指標
```promql
# Pod CPU 使用率
rate(container_cpu_usage_seconds_total{namespace="default"}[5m])

# Pod 內存使用
container_memory_usage_bytes{namespace="default"}

# Pod 重啟次數
kube_pod_container_status_restarts_total
```

### HPA 相關指標
```promql
# 當前副本數
kube_deployment_status_replicas{deployment="app"}

# 期望副本數
kube_deployment_spec_replicas{deployment="app"}

# CPU 請求/使用比
rate(container_cpu_usage_seconds_total[5m]) / on(pod) kube_pod_container_resource_requests{resource="cpu"}
```

## 數據保留
- 默認保留時間: 15 天
- 可以通過修改 `--storage.tsdb.retention.time` 參數調整

## 持久化存儲 (可選)

目前使用 `emptyDir`，重啟會丟失數據。如需持久化：

### 創建 PVC
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-storage
  namespace: monitoring
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
```

### 修改 Deployment
將 `emptyDir` 改為：
```yaml
volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: prometheus-storage
```

## 故障排查

### Pod 無法啟動
```bash
kubectl describe pod -n monitoring -l app=prometheus
kubectl logs -n monitoring -l app=prometheus
```

### 無法抓取指標
1. 檢查 target 狀態: 訪問 `http://localhost:30090/targets`
2. 檢查 RBAC 權限: `kubectl auth can-i list pods --as=system:serviceaccount:monitoring:prometheus`
3. 檢查網絡連接: `kubectl exec -n monitoring -it <prometheus-pod> -- wget -O- http://app.default.svc.cluster.local:8080/actuator/prometheus`

### Spring Boot 指標不顯示
1. 確認 actuator 端點已暴露
2. 測試端點: `curl http://localhost:30000/actuator/prometheus`
3. 檢查 pod 注解是否正確

## 下一步
- 安裝 Grafana 進行可視化: 參考 `prometheus/grafana-deployment.yaml`
- 配置 AlertManager 進行告警
- 添加更多自定義指標

## 資源需求
- CPU: 250m (request) - 1000m (limit)
- Memory: 512Mi (request) - 2Gi (limit)
- 存儲: 動態增長，建議配置持久化卷

## 安全建議
1. 啟用身份驗證 (通過 Nginx/Ingress)
2. 限制網絡訪問 (NetworkPolicy)
3. 定期更新 Prometheus 版本
4. 監控 Prometheus 本身的資源使用
