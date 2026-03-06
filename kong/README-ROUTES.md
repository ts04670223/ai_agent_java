# Kong 路由配置說明

## 問題原因

當訪問 `http://test6.test/api/cart/2` 時出現：
```json
{
  "message":"no Route matched with those values",
  "request_id":"..."
}
```

**原因：** Kong 啟動後是空白狀態，**沒有配置任何服務和路由**。Kong 作為 API Gateway，需要手動配置路由規則才能將請求轉發到後端服務。

## 解決方案

已創建**自動化配置系統**，確保 Kong 路由在系統啟動時自動配置。

### 自動化方案

#### 方案 1：Kubernetes Job（推薦）
系統會在啟動時自動運行 `kong-setup-routes` Job 來配置路由。

**配置檔案：** `kong/kong-setup-routes-job.yaml`

**特點：**
- ✅ 自動檢測配置是否存在
- ✅ 冪等性（重複執行不會出錯）
- ✅ 等待 Kong 完全就緒後才執行
- ✅ 自動測試路由是否正常

#### 方案 2：健康檢查腳本（自動修復）
提供 `check-and-configure.sh` 腳本，自動檢查並修復配置。

**使用方式：**
```bash
vagrant ssh -c "bash /vagrant/kong/check-and-configure.sh"
```

**功能：**
1. 檢查 Kong 是否運行
2. 檢查路由配置是否存在
3. 如果配置缺失，自動執行 Job 修復
4. 測試路由是否正常工作

### 系統啟動時自動配置

已在 **Vagrantfile** 中添加自動配置：

```ruby
config.vm.provision "shell", inline: <<-SHELL
  echo "等待 Kong 完全啟動..."
  sleep 30
  
  # 執行 Kong 配置檢查和自動配置
  echo "執行 Kong 配置檢查..."
  bash /vagrant/kong/check-and-configure.sh
SHELL
```

這意味著：
- ✅ `vagrant up` - 首次啟動時自動配置
- ✅ `vagrant provision` - 重新執行 provision 時自動配置
- ✅ `vagrant reload --provision` - 重啟並重新配置

### 當前配置

#### Service（服務定義）
- **名稱：** `spring-boot-app`
- **URL：** `http://app.default.svc.cluster.local:8080`
- **說明：** 指向 Kubernetes 中的 Spring Boot 後端應用

#### Route（路由規則）
- **名稱：** `api-route`
- **路徑：** `/api`
- **說明：** 所有 `/api/*` 開頭的請求都會轉發到後端應用
- **strip_path：** `false`（保留 `/api` 前綴）

### 配置方式

#### 方法 1：使用腳本（推薦）
```bash
# 在 VM 內執行
vagrant ssh
bash /vagrant/kong/setup-routes.sh
```

#### 方法 2：手動配置
```bash
# 1. 創建 Service
curl -i -X POST http://localhost:30003/services \
  --data name=spring-boot-app \
  --data url=http://app.default.svc.cluster.local:8080

# 2. 創建 Route
curl -i -X POST http://localhost:30003/services/spring-boot-app/routes \
  --data 'name=api-route' \
  --data 'paths[]=/api' \
  --data 'strip_path=false'
```

## 驗證配置

### 查看已配置的服務和路由
```bash
# 查看所有 Services
curl -s http://localhost:30003/services | jq .

# 查看所有 Routes
curl -s http://localhost:30003/routes | jq .
```

### 測試 API 端點
```bash
# 產品列表
curl http://localhost:30000/api/products

# 購物車
curl http://localhost:30000/api/cart/2

# 從外部訪問（需設定 hosts）
curl http://test6.test/api/cart/2
```

### 測試結果
```json
// http://localhost:30000/api/cart/2
{
  "total": 80290.00,
  "success": true,
  "id": 2,
  "userId": 2,
  "items": [
    {
      "quantity": 1,
      "productId": 1,
      "price": 35900.00,
      "subtotal": 35900.00,
      "id": 1,
      "productName": "iPhone 15 Pro",
      "productPrice": 35900.00
    },
    // ... 更多商品
  ],
  "itemCount": 3
}
```

## 可用的 API 端點

通過 Kong Gateway (http://localhost:30000 或 http://test6.test)：

### 產品 API
- `GET /api/products` - 產品列表
- `GET /api/products/{id}` - 單一產品
- `GET /api/products/featured` - 精選產品
- `GET /api/products/category/{category}` - 分類產品
- `POST /api/products` - 新增產品
- `PUT /api/products/{id}` - 更新產品
- `DELETE /api/products/{id}` - 刪除產品

### 購物車 API
- `GET /api/cart/{userId}` - 取得購物車
- `POST /api/cart/{userId}/items` - 加入商品
- `PUT /api/cart/{userId}/items/{itemId}` - 更新數量
- `DELETE /api/cart/{userId}/items/{itemId}` - 移除商品
- `DELETE /api/cart/{userId}/clear` - 清空購物車

### 訂單 API
- `GET /api/orders` - 訂單列表
- `GET /api/orders/{id}` - 訂單詳情
- `POST /api/orders` - 建立訂單
- `PUT /api/orders/{id}/status` - 更新訂單狀態

### 聊天 API
- `GET /api/chat/unread-count/{userId}` - 未讀訊息數
- `GET /api/chat/conversations/{userId}` - 對話列表
- `GET /api/chat/messages/{conversationId}` - 訊息列表
- `POST /api/chat/messages` - 發送訊息

## 管理 Kong 配置

### Kong Admin API（端口 30003）

```bash
# 列出所有 Services
curl http://localhost:30003/services

# 列出所有 Routes
curl http://localhost:30003/routes

# 刪除 Route
curl -X DELETE http://localhost:30003/routes/{route-id}

# 刪除 Service
curl -X DELETE http://localhost:30003/services/{service-id}

# 更新 Route
curl -X PATCH http://localhost:30003/routes/{route-id} \
  --data 'paths[]=/api/v2'
```

### Kong GUI（端口 30002）

也可以通過 Web 界面管理：
```
http://192.168.10.10:30002
```

## 添加更多路由

如果需要為其他服務添加路由：

### 例如：直接訪問後端（繞過 Kong）
```bash
# 創建直接路由
curl -X POST http://localhost:30003/services/spring-boot-app/routes \
  --data 'name=direct-route' \
  --data 'paths[]=/direct' \
  --data 'strip_path=true'
```

### 例如：WebSocket 路由
```bash
# 為 WebSocket 添加路由
curl -X POST http://localhost:30003/services/spring-boot-app/routes \
  --data 'name=websocket-route' \
  --data 'paths[]=/ws' \
  --data 'protocols[]=http' \
  --data 'protocols[]=https'
```

## 常見問題

### Q1: 重啟後路由消失了？
**A:** 不會！系統已配置自動化方案：

1. **Vagrantfile 自動配置** - 每次 `vagrant up` 或 `vagrant provision` 時自動檢查和配置
2. **Kubernetes Job** - 如果路由缺失會自動創建
3. **健康檢查腳本** - 手動檢查和修復

如果需要手動觸發：
```bash
vagrant ssh -c "bash /vagrant/kong/check-and-configure.sh"
```

或重新創建 Job：
```bash
vagrant ssh -c "bash /vagrant/kong/reconfigure-routes.sh"
```

### Q2: 如何查看 Kong 日誌？
```bash
kubectl logs -f -l io.kompose.service=kong
```

### Q3: 如何測試後端應用是否正常？
```bash
# 直接訪問後端（繞過 Kong）
vagrant ssh -c "curl http://app.default.svc.cluster.local:8080/api/products"
```

### Q4: 如何添加認證？
```bash
# 啟用 Key Auth 插件
curl -X POST http://localhost:30003/routes/api-route/plugins \
  --data "name=key-auth"
```

## 路由流程圖

```
瀏覽器
  ↓
http://test6.test/api/cart/2
  ↓
Nginx (端口 80)
  ↓
Kong Gateway (端口 30000)
  ↓
Route: /api -> Service: spring-boot-app
  ↓
Spring Boot App (app:8080)
  ↓
MySQL / Redis
  ↓
返回 JSON 響應
```

## 腳本文件

- **配置腳本：** `kong/setup-routes.sh`
- **Kong K8s 配置：** `kong/kong-k8s.yaml`
- **預防措施文檔：** `kong/README-PREVENTION.md`

## 自動化配置

如果想在系統啟動時自動配置路由，可以將腳本添加到 Vagrantfile：

```ruby
config.vm.provision "shell", inline: <<-SHELL
  echo "配置 Kong 路由..."
  sleep 10  # 等待 Kong 完全啟動
  bash /vagrant/kong/setup-routes.sh
SHELL
```

---
最後更新：2026-01-22
配置狀態：✅ 已配置並測試通過
