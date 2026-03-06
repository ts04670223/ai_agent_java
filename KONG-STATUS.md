# Kong + test6.test 設定狀態總結

> ⭐ **完整指南**: 請查看 [TEST6-UNIFIED-ACCESS.md](TEST6-UNIFIED-ACCESS.md)

## ✅ 已完成的設定

### 1. Kong Gateway 配置
- **Kong Proxy**: `http://192.168.10.10:30000` ✅ 運行正常
- **Kong Admin API**: `http://192.168.10.10:30003` ✅ 運行正常  
- **Kong Admin GUI**: `http://192.168.10.10:30002` ✅ 可訪問

### 2. Kong 路由配置

**後端 API**:
```bash
Service: app-service → http://app:8080
Route: test6.test/api → app-service
Plugins: CORS (已啟用)
```

**監控服務**:
```bash
Service: prometheus → prometheus.monitoring.svc.cluster.local:9090
Route: test6.test/prometheus → Prometheus

Service: grafana → grafana.monitoring.svc.cluster.local:3000
Route: test6.test/grafana → Grafana
```

### 3. Nginx 反向代理配置
```nginx
http://test6.test/            → Vite (port 3000) ✅ 正常
http://test6.test/api         → Kong → Spring Boot ✅ 正常
http://test6.test/prometheus  → Kong → Prometheus ✅ 正常
http://test6.test/grafana     → Kong → Grafana ✅ 正常
```

### 4. 請求流程驗證
測試指令：
```bash
curl -I -H "Host: test6.test" http://192.168.10.10/api
```

Response Headers：
- ✅ `Via: 1.1 kong/3.9.1` - 確認經過 Kong
- ✅ `X-Kong-Request-Id` - Kong 追蹤 ID
- ✅ `Access-Control-Allow-Origin: *` - CORS 生效
- ⚠️ `502 Bad Gateway` - 後端應用問題

---

## ⚠️ 當前問題

### Spring Boot 應用無法啟動
**錯誤**: 資料庫連接失敗
```
Could not obtain connection to query metadata
NullPointerException in JdbcIsolationDelegate
```

### 解決步驟

#### 1. 檢查 MySQL 是否正常運行
```bash
vagrant ssh -c "kubectl logs mysql-7c75769948-gb87r --tail=20"
```

#### 2. 檢查資料庫連線設定
當前配置：
```
SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/spring_boot_demo
SPRING_DATASOURCE_USERNAME=springboot
SPRING_DATASOURCE_PASSWORD=springboot123
```

#### 3. 測試資料庫連線
```bash
vagrant ssh -c "kubectl exec -it mysql-7c75769948-gb87r -- mysql -u springboot -pspringboot123 spring_boot_demo -e 'SELECT 1'"
```

#### 4. 重新部署應用（修正後）
```bash
vagrant ssh -c "kubectl rollout restart deployment/app"
```

---

## 🎯 測試步驟

### 前端測試（應該正常）
```bash
curl -I http://192.168.10.10
# 預期: HTTP/1.1 200 OK, Server: nginx/1.18.0
```

### Kong 測試（應該正常）
```bash
curl -I -H "Host: test6.test" http://192.168.10.10:30000/api
# 預期: 看到 Via: 1.1 kong/3.9.1
```

### 完整流程測試（等後端修復）
```bash
curl -H "Host: test6.test" http://192.168.10.10/api/products
# 預期: 返回產品 JSON 數據
```

---

## 📝 待辦事項

- [ ] 修復 MySQL 資料庫連線問題
- [ ] 確認資料庫使用者權限
- [ ] 驗證應用成功啟動 (port 8080)
- [ ] 測試完整 API 流程
- [ ] 在主機設定 hosts: `192.168.10.10 test6.test`

---

## 🔗 相關指令

### 查看所有 Pod 狀態
```bash
vagrant ssh -c "kubectl get pods"
```

### 查看應用日誌
```bash
vagrant ssh -c "kubectl logs -f deployment/app"
```

### 查看 Kong 配置
```bash
vagrant ssh -c "curl -s http://192.168.10.10:30003/services"
vagrant ssh -c "curl -s http://192.168.10.10:30003/routes"
```

### 重啟服務
```bash
vagrant ssh -c "kubectl rollout restart deployment/app"
vagrant ssh -c "sudo systemctl reload nginx"
```
