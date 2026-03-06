# ✅ test6.test 域名驗證報告

**驗證時間**: 2026-01-22  
**狀態**: ✅ 所有服務正常

## 📋 配置驗證

### 1. Windows Hosts 配置
```
✅ 已配置: 192.168.10.10 test6.test
位置: C:\Windows\System32\drivers\etc\hosts
```

### 2. Nginx 配置
```
✅ 配置有效
文件: /etc/nginx/sites-available/test6.test
測試: nginx -t → successful
```

### 3. Kong Gateway
```
✅ 運行正常
Admin API: http://localhost:30003
Proxy: http://192.168.10.10:30000
```

## 🌐 服務訪問測試

| 服務 | URL | 狀態 | 說明 |
|------|-----|:----:|------|
| **前端** | http://test6.test/ | ✅ HTTP 200 | Vite React 應用 |
| **後端 API** | http://test6.test/api/products | ✅ HTTP 200 | Spring Boot REST API |
| **Prometheus** | http://test6.test/prometheus | ✅ HTTP 200 | 監控資料庫 |
| **Grafana** | http://test6.test/grafana | ✅ HTTP 302 | 監控儀表板 (重定向登入) |

## 🔗 完整路由流程

```
瀏覽器
  ↓
test6.test (Nginx Port 80)
  ↓
192.168.10.10:30000 (Kong Gateway)
  ↓
  ├─ /api → spring-boot-app.default.svc.cluster.local:8080
  │         └─ Spring Boot Pod (2/2 Running)
  │
  ├─ /prometheus → prometheus.monitoring.svc.cluster.local:9090
  │                └─ Prometheus Pod (1/1 Running)
  │
  └─ /grafana → grafana.monitoring.svc.cluster.local:3000
                └─ Grafana Pod (1/1 Running)
```

## 📊 Kong 路由配置

| 路由名稱 | 路徑 | 目標服務 | Strip Path | Preserve Host |
|---------|------|---------|-----------|--------------|
| **api-route** | /api | spring-boot-app | ❌ false | ❌ false |
| **prometheus-route** | /prometheus | prometheus | ✅ true | ❌ false |
| **grafana-route** | /grafana | grafana | ❌ false | ✅ true |

### Strip Path 說明
- **true**: 移除路徑前綴（如 /prometheus → /）
- **false**: 保留完整路徑（如 /api → /api）

## 🎯 Nginx 反向代理配置

**文件**: `/etc/nginx/sites-available/test6.test`

```nginx
server {
    listen 80;
    server_name test6.test;

    # 前端 → 本地 Vite
    location / {
        proxy_pass http://127.0.0.1:3000;
    }

    # API → Kong Gateway
    location /api {
        proxy_pass http://192.168.10.10:30000;
    }

    # Prometheus → Kong Gateway
    location /prometheus {
        proxy_pass http://192.168.10.10:30000/prometheus;
    }

    # Grafana → Kong Gateway
    location /grafana {
        proxy_pass http://192.168.10.10:30000/grafana;
    }
}
```

## ✅ 驗證結果

### 成功測試

1. ✅ **前端訪問**: http://test6.test/ → 200 OK
2. ✅ **API 訪問**: http://test6.test/api/products → 200 OK，返回商品列表 JSON
3. ✅ **Prometheus**: http://test6.test/prometheus/graph → 200 OK
4. ✅ **Grafana**: http://test6.test/grafana → 302 重定向到登入頁

### Kong 連接測試

```bash
# VM 內部測試
curl http://localhost:30000/api/products          # ✅ 200 OK
curl http://localhost:30000/prometheus/api/v1/... # ✅ 200 OK
curl http://localhost:30000/grafana/api/health    # ✅ 302 Found
```

### 端到端測試

```bash
# 從 Windows 主機測試
curl http://test6.test/api/products               # ✅ 200 OK
curl http://test6.test/prometheus/api/v1/...      # ✅ 200 OK
curl http://test6.test/grafana                    # ✅ 302 Found
```

## 📈 Pod 狀態

### 應用 Pod (default namespace)
```
NAME                   READY   STATUS    RESTARTS   AGE
app-xxx                2/2     Running   0          26h
```

### 監控 Pod (monitoring namespace)
```
NAME                          READY   STATUS    RESTARTS   AGE
prometheus-xxx                1/1     Running   1          111m
grafana-xxx                   1/1     Running   0          44m
```

## 🔧 驗證工具

已創建驗證腳本：

**Windows**: `tools/verify-test6-domain.bat`
```cmd
.\tools\verify-test6-domain.bat
```

**功能**:
1. 檢查 Windows hosts 配置
2. 驗證 Nginx 配置語法
3. 查詢 Kong 路由列表
4. 測試所有服務連通性
5. 檢查 Pod 狀態

## 📝 結論

✅ **test6.test 域名配置完整且正常運行**

所有服務都可以通過統一的 test6.test 域名訪問：
- ✅ Kong Gateway 正常路由所有請求
- ✅ Prometheus 監控正常運作
- ✅ Grafana 儀表板可正常訪問
- ✅ Spring Boot API 正常響應
- ✅ 前端應用正常顯示

**架構總覽**:
```
test6.test (統一入口)
    ↓
Nginx (反向代理)
    ↓
Kong Gateway (API 閘道)
    ↓
Kubernetes Services (微服務)
```

---

**驗證完成時間**: 2026-01-22 18:04  
**所有測試**: ✅ 通過  
**建議**: 可以正常使用 http://test6.test/ 訪問所有服務
