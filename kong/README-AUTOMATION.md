# Kong 自動化配置完整指南

## 問題已解決 ✅

您的系統現在已配置完整的自動化方案，**下次重啟時不會再出現路由配置問題**。

## 實施的自動化方案

### 1. Kubernetes Job 自動配置 ⭐ 主要方案

**檔案：** `kong/kong-setup-routes-job.yaml`

#### 工作原理：
```
系統啟動
   ↓
Kong 啟動完成
   ↓
等待 Kong Admin API 就緒 (init container)
   ↓
檢查路由配置是否存在
   ↓
如果不存在 → 自動創建
如果已存在 → 跳過（冪等性）
   ↓
測試路由
   ↓
配置完成 ✓
```

#### 特點：
- ✅ **冪等性**：重複執行不會出錯
- ✅ **智能檢測**：只在配置缺失時才創建
- ✅ **自動等待**：確保 Kong 完全就緒後才執行
- ✅ **自動測試**：配置後自動驗證

### 2. Vagrantfile 自動執行

**修改位置：** `Vagrantfile`

```ruby
config.vm.provision "shell", inline: <<-SHELL
  echo "等待 Kong 完全啟動..."
  sleep 30
  
  # 執行 Kong 配置檢查和自動配置
  echo "執行 Kong 配置檢查..."
  bash /vagrant/kong/check-and-configure.sh
SHELL
```

#### 觸發時機：
- ✅ `vagrant up` - 首次啟動
- ✅ `vagrant provision` - 重新執行 provision
- ✅ `vagrant reload --provision` - 重啟並重新配置

### 3. 健康檢查和自動修復腳本

**檔案：** `kong/check-and-configure.sh`

#### 功能：
1. 檢查 Kong 是否運行
2. 等待 Kong Admin API 就緒
3. 檢查路由配置是否存在
4. **如果配置缺失 → 自動觸發 Job 修復**
5. 測試路由是否正常

#### 手動執行：
```bash
vagrant ssh -c "bash /vagrant/kong/check-and-configure.sh"
```

### 4. 快速重新配置腳本

**檔案：** `kong/reconfigure-routes.sh`

用於快速重置和重新配置路由：
```bash
vagrant ssh -c "bash /vagrant/kong/reconfigure-routes.sh"
```

## 測試結果

### ✅ 測試 1：模擬配置丟失並自動恢復
```bash
# 刪除所有路由配置
kubectl delete job kong-setup-routes
curl -X DELETE http://localhost:30003/routes/{route-id}
curl -X DELETE http://localhost:30003/services/{service-id}

# 執行檢查腳本
bash /vagrant/kong/check-and-configure.sh

# 結果：自動檢測到配置缺失，創建 Job，配置成功 ✓
```

### ✅ 測試 2：API 路由正常工作
```bash
curl http://localhost:30000/api/products
# 返回：產品列表 JSON ✓

curl http://localhost:30000/api/cart/2
# 返回：購物車資料 JSON ✓
```

### ✅ 測試 3：冪等性測試
```bash
# 重複執行配置
bash /vagrant/kong/check-and-configure.sh
bash /vagrant/kong/check-and-configure.sh
bash /vagrant/kong/check-and-configure.sh

# 結果：檢測到配置已存在，跳過創建 ✓
```

## 完整啟動流程

```
1. vagrant up / vagrant reload --provision
   ↓
2. 系統啟動，Docker 和 Kubernetes 初始化
   ↓
3. PostgreSQL 啟動
   ↓
4. Kong Migrations Job 執行（初始化資料庫）
   ↓
5. Kong Deployment 啟動
   ├─ wait-for-db (init)
   ├─ wait-for-migrations (init)
   └─ kong (main)
   ↓
6. Vagrantfile provision 執行
   ↓
7. check-and-configure.sh 自動執行
   ├─ 檢查 Kong 狀態
   ├─ 檢查路由配置
   └─ 如果缺失 → 觸發 kong-setup-routes Job
   ↓
8. kong-setup-routes Job 執行
   ├─ wait-for-kong (init)
   ├─ 檢查並創建 Service
   ├─ 檢查並創建 Route
   └─ 測試路由
   ↓
9. ✓ 系統完全就緒，路由配置完成
```

## 驗證方法

### 檢查所有組件狀態
```bash
# 1. 檢查所有 pod
vagrant ssh -c "kubectl get pods"

# 2. 檢查 Kong 配置 Job
vagrant ssh -c "kubectl get jobs kong-setup-routes"

# 3. 查看配置日誌
vagrant ssh -c "kubectl logs job/kong-setup-routes"

# 4. 檢查 Kong 路由
vagrant ssh -c "curl -s http://localhost:30003/services"
vagrant ssh -c "curl -s http://localhost:30003/routes"

# 5. 測試 API
vagrant ssh -c "curl -s http://localhost:30000/api/products | head -c 200"
```

## 故障排除

### 情境 1：重啟後路由不工作

**解決方案：**
```bash
# 執行健康檢查腳本（會自動修復）
vagrant ssh -c "bash /vagrant/kong/check-and-configure.sh"
```

### 情境 2：手動刪除了配置

**解決方案：**
```bash
# 使用快速重新配置腳本
vagrant ssh -c "bash /vagrant/kong/reconfigure-routes.sh"
```

### 情境 3：Job 執行失敗

**排查步驟：**
```bash
# 1. 查看 Job 狀態
kubectl get jobs kong-setup-routes

# 2. 查看詳細日誌
kubectl logs job/kong-setup-routes

# 3. 查看 init container 日誌
kubectl logs job/kong-setup-routes -c wait-for-kong

# 4. 檢查 Kong 是否運行
kubectl get pods -l io.kompose.service=kong

# 5. 手動測試 Kong Admin API
curl http://localhost:30003/services
```

### 情境 4：Provision 時配置未執行

**解決方案：**
```bash
# 重新執行 provision
vagrant provision

# 或者手動執行配置檢查
vagrant ssh -c "bash /vagrant/kong/check-and-configure.sh"
```

## 檔案清單

### 核心配置檔案
- ✅ `kong/kong-setup-routes-job.yaml` - Kubernetes Job 配置
- ✅ `kong/check-and-configure.sh` - 健康檢查和自動修復腳本
- ✅ `kong/reconfigure-routes.sh` - 快速重新配置腳本
- ✅ `kong/setup-routes.sh` - 原始手動配置腳本（保留）
- ✅ `Vagrantfile` - 已添加自動配置 provision

### 說明文檔
- ✅ `kong/README-ROUTES.md` - 路由配置說明
- ✅ `kong/README-PREVENTION.md` - 異常預防措施
- ✅ `kong/README-AUTOMATION.md` - 本文檔（自動化指南）

## 維護建議

### 定期檢查
```bash
# 每次重大更新後執行
vagrant ssh -c "bash /vagrant/kong/check-and-configure.sh"
```

### 備份 Kong 配置
```bash
# 導出 Kong 配置
vagrant ssh -c "curl -s http://localhost:30003/services > kong-services-backup.json"
vagrant ssh -c "curl -s http://localhost:30003/routes > kong-routes-backup.json"
```

### 更新路由規則

如果需要修改路由規則，編輯 `kong-setup-routes-job.yaml` 中的配置，然後：
```bash
vagrant ssh -c "bash /vagrant/kong/reconfigure-routes.sh"
```

## 優勢總結

### ✅ 自動化
- 無需手動干預
- 系統啟動時自動配置
- 配置丟失自動修復

### ✅ 可靠性
- 多層檢查機制
- 冪等性保證
- 自動測試驗證

### ✅ 可維護性
- 清晰的配置檔案
- 詳細的日誌輸出
- 完整的文檔說明

### ✅ 靈活性
- 支援手動觸發
- 支援快速重置
- 支援自定義配置

## 下次啟動

當您下次執行以下任何操作時，路由配置將自動完成：

```bash
# 重啟 VM
vagrant reload --provision

# 重新 provision
vagrant provision

# 完全重建
vagrant destroy && vagrant up

# 手動檢查
vagrant ssh -c "bash /vagrant/kong/check-and-configure.sh"
```

**結果：** 無需任何手動配置，API 路由自動就緒！ 🎉

---
最後更新：2026-01-22  
狀態：✅ 完全自動化，已測試驗證
