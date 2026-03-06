# ⚠️ 重要提醒: 需要重建 Spring Boot 應用

## 📝 為什麼需要重建

Prometheus 監控系統已經安裝完成，但為了讓 Spring Boot 應用能夠暴露 Prometheus 格式的指標，我們對以下檔案進行了修改:

### 1. pom.xml
添加了 `micrometer-registry-prometheus` 依賴:
```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
    <scope>runtime</scope>
</dependency>
```

### 2. application.properties
添加了 Actuator 和 Prometheus 配置:
```properties
management.endpoints.web.exposure.include=health,info,prometheus,metrics
management.endpoint.health.show-details=always
management.endpoint.prometheus.enabled=true
management.metrics.export.prometheus.enabled=true
management.metrics.tags.application=${spring.application.name}
```

### 3. app-deployment.yaml
添加了 Prometheus 注解:
```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/actuator/prometheus"
```

## 🔨 如何重建並部署

### 選項 1: 使用 Docker 重建 (推薦)

```bash
# 1. 重新構建 Docker 映像
vagrant ssh
cd /vagrant
mvn clean package -DskipTests
docker build -t spring-boot-app:latest .

# 2. 重新部署應用
kubectl rollout restart deployment/app

# 3. 等待部署完成
kubectl rollout status deployment/app

# 4. 驗證 Actuator 端點
kubectl exec -it $(kubectl get pod -l io.kompose.service=app -o jsonpath='{.items[0].metadata.name}') -- wget -qO- http://localhost:8080/actuator/prometheus | head -20
```

### 選項 2: 使用現有腳本

如果你有自動化部署腳本:
```bash
# Windows
tools\rebuild-docker.bat

# 或在 VM 內
vagrant ssh
bash /vagrant/scripts/your-deploy-script.sh
```

## ✅ 驗證步驟

### 1. 檢查 Actuator 端點是否可用

```bash
vagrant ssh -c "kubectl exec -it \$(kubectl get pod -l io.kompose.service=app -o jsonpath='{.items[0].metadata.name}') -- wget -qO- http://localhost:8080/actuator/prometheus | head -20"
```

**預期輸出** (應該看到 Prometheus 格式的指標):
```
# HELP jvm_memory_used_bytes The amount of used memory
# TYPE jvm_memory_used_bytes gauge
jvm_memory_used_bytes{application="Spring Boot Demo",area="heap",id="G1 Survivor Space"} 1048576.0
...
```

**錯誤輸出** (如果還沒重建):
```
404 Not Found
```
或
```
Whitelabel Error Page
```

### 2. 檢查 Prometheus 是否發現目標

訪問: http://localhost:30090/targets

搜索 `spring-boot-app`:
- ✅ **正確**: 顯示多個 endpoints，狀態為 UP
- ❌ **錯誤**: 顯示錯誤訊息 (404, connection refused, etc.)

### 3. 測試 PromQL 查詢

訪問: http://localhost:30090/graph

執行查詢:
```promql
up{job="spring-boot-app"}
```

- ✅ **正確**: 返回 `1`
- ❌ **錯誤**: 沒有數據或返回 `0`

## 🚀 完整的重建和部署流程

### 方法 A: 完整重建 (推薦用於確保一切正常)

```bash
# 在 Windows 主機上
cd C:\JOHNY\test

# SSH 到 VM
vagrant ssh

# 在 VM 內執行
cd /vagrant

# 1. 清理並重新構建
mvn clean package -DskipTests

# 2. 構建新的 Docker 映像
docker build -t spring-boot-app:latest .

# 3. 重新部署
kubectl apply -f app-deployment.yaml

# 4. 等待新 Pod 就緒
kubectl rollout status deployment/app

# 5. 驗證
kubectl get pods -l io.kompose.service=app
```

### 方法 B: 快速重啟 (如果映像已經存在)

```bash
vagrant ssh -c "kubectl rollout restart deployment/app"
vagrant ssh -c "kubectl rollout status deployment/app"
```

⚠️ **注意**: 方法 B 只適用於映像已包含最新的 pom.xml 和 application.properties 更改。

## 🔍 常見問題

### Q1: 為什麼不能直接重啟 Pod?
**A**: 因為 pom.xml 的更改需要重新編譯，並且 Docker 映像需要包含新的依賴。

### Q2: 我可以使用熱重載嗎?
**A**: 在開發環境中可以使用 Spring Boot DevTools，但在 Kubernetes 中部署時建議完整重建。

### Q3: 重建需要多長時間?
**A**: 
- Maven 構建: 1-3 分鐘
- Docker 構建: 30秒 - 2 分鐘
- Kubernetes 部署: 1-2 分鐘
- 總計: 約 3-7 分鐘

### Q4: 會影響現有功能嗎?
**A**: 不會。我們只是添加了新的 Actuator 端點，不會影響現有的業務邏輯。

### Q5: 如果重建失敗怎麼辦?
**A**: 
1. 檢查 Maven 錯誤: `mvn clean package`
2. 檢查 Docker 錯誤: `docker build -t spring-boot-app:latest .`
3. 檢查 Kubernetes 錯誤: `kubectl describe pod -l io.kompose.service=app`

## 📋 重建後的驗證清單

完成重建後，確認以下項目:

- [ ] Maven 構建成功 (沒有錯誤)
- [ ] Docker 映像構建成功
- [ ] 新 Pod 已啟動並處於 Running 狀態
- [ ] `/actuator/health` 端點返回 UP
- [ ] `/actuator/prometheus` 端點返回指標數據
- [ ] Prometheus Targets 頁面顯示 spring-boot-app 為 UP
- [ ] 可以在 Prometheus 中查詢 `up{job="spring-boot-app"}`
- [ ] 現有功能正常工作 (購物車、商品等)

## 🎯 下一步

重建完成後:

1. ✅ 訪問 Prometheus: http://localhost:30090
2. ✅ 查看 Targets: http://localhost:30090/targets
3. ✅ 執行查詢測試
4. ✅ (可選) 安裝 Grafana 進行可視化
5. ✅ 配置告警規則

## 📚 相關文檔

- [QUICKSTART.md](QUICKSTART.md) - Prometheus 快速開始指南
- [README.md](README.md) - 完整的 Prometheus 文檔
- [INSTALLATION-SUMMARY.md](INSTALLATION-SUMMARY.md) - 安裝摘要

---

**重要**: 在重建應用之前，Prometheus 雖然已經安裝並運行，但無法從 Spring Boot 應用收集到指標數據。完成重建後，整個監控系統才能完全正常工作。
