# 🎛️ Kubernetes Dashboard 管理頁面安裝包

**版本**: 1.0.0  
**Dashboard 版本**: v2.7.0  
**發布日期**: 2025-12-19

---

## 📦 安裝包概述

這是一個完整的 Kubernetes Dashboard 部署方案，提供 Web 圖形界面管理 Kubernetes 集群。

### 主要特點

✅ **一鍵安裝** - Windows 批處理腳本自動化部署  
✅ **自動配置** - 自動創建管理員用戶和訪問令牌  
✅ **開箱即用** - 包含啟動、停止、訪問等完整工具  
✅ **詳細文檔** - 完整的使用說明和故障排查指南

## 📁 安裝包內容

```
k8s-dashboard/
├── install-dashboard.sh        # Linux 安裝腳本（核心）
├── install-dashboard.bat       # Windows 安裝腳本
├── start-dashboard.bat         # 啟動 Dashboard（推薦使用）
├── stop-dashboard.bat          # 停止 Dashboard
├── access-dashboard.bat        # 查看訪問信息
├── uninstall-dashboard.sh      # 卸載腳本
├── README.md                   # 完整使用文檔
└── dashboard-token.txt         # 訪問令牌（安裝後生成）
```

## 🚀 快速開始（3 步驟）

### 步驟 1: 安裝 Dashboard

```cmd
cd k8s-dashboard
install-dashboard.bat
```

安裝過程約 2-3 分鐘，會自動：
- 部署 Dashboard 到 Kubernetes
- 創建管理員用戶
- 生成訪問令牌

### 步驟 2: 啟動服務

```cmd
start-dashboard.bat
```

這會：
- 啟動 kubectl proxy
- 自動打開瀏覽器
- 顯示訪問令牌

### 步驟 3: 登入 Dashboard

1. 瀏覽器會自動打開 Dashboard 登入頁
2. 選擇 **Token** 登入方式
3. 複製 `dashboard-token.txt` 中的令牌
4. 點擊 **Sign in**

**訪問地址**: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

## 📋 前置需求

### 必須完成

✅ **Vagrant VM 已啟動**
```cmd
vagrant up
```

✅ **Kubernetes 集群已安裝**
```bash
vagrant ssh
kubectl get nodes  # 應該顯示 Ready 狀態
```

如果 Kubernetes 未安裝：
```cmd
vagrant ssh
sudo bash /vagrant/scripts/install-k8s.sh
```

### 系統需求

- **VirtualBox**: 7.0+
- **Vagrant**: 2.4+
- **Kubernetes**: 1.21+
- **記憶體**: VM 至少 4GB RAM
- **磁碟**: 至少 10GB 可用空間

## 🛠️ 工具說明

### install-dashboard.bat

**功能**: 安裝 Kubernetes Dashboard

**執行**:
```cmd
cd k8s-dashboard
install-dashboard.bat
```

**操作**:
1. 檢查 Vagrant VM 狀態
2. 檢查 Kubernetes 狀態
3. 執行 install-dashboard.sh 腳本
4. 部署 Dashboard
5. 創建管理員用戶
6. 生成訪問令牌

**輸出**:
- Dashboard Pod 部署成功
- 管理員用戶已創建
- 令牌已保存到 `dashboard-token.txt`

### start-dashboard.bat

**功能**: 啟動 Dashboard 並打開瀏覽器

**執行**:
```cmd
start-dashboard.bat
```

**操作**:
1. 檢查 VM 和 Dashboard 狀態
2. 啟動 kubectl proxy（後台）
3. 等待 5 秒
4. 自動打開瀏覽器
5. 顯示令牌信息

**注意**: 
- 會開啟新的終端視窗運行 kubectl proxy
- 請保持該視窗開啟
- 關閉視窗將停止 Dashboard 訪問

### stop-dashboard.bat

**功能**: 停止 kubectl proxy

**執行**:
```cmd
stop-dashboard.bat
```

**操作**:
- 結束 VM 中的 kubectl proxy 進程

**替代方式**:
- 直接關閉 "Kubernetes Dashboard Proxy" 終端視窗

### access-dashboard.bat

**功能**: 顯示訪問信息

**執行**:
```cmd
access-dashboard.bat
```

**顯示內容**:
- Dashboard 訪問地址
- 訪問令牌
- 啟動命令
- 常用操作

### uninstall-dashboard.sh

**功能**: 完全卸載 Dashboard

**執行**:
```bash
vagrant ssh
sudo bash /vagrant/k8s-dashboard/uninstall-dashboard.sh
```

**操作**:
1. 刪除管理員用戶
2. 卸載 Dashboard 部署
3. 清理令牌文件

**警告**: 此操作不可逆！

## 📊 Dashboard 功能

安裝後可通過 Web 界面管理：

### 工作負載管理
- 📦 **Deployments** - 部署管理
- 🎯 **Pods** - 容器組管理
- 📝 **Logs** - 實時日誌查看
- 💻 **Exec** - 進入容器終端

### 服務與網路
- 🌐 **Services** - 服務管理
- 🔀 **Ingress** - 入口規則

### 配置與存儲
- ⚙️ **ConfigMaps** - 配置映射
- 🔐 **Secrets** - 密鑰管理
- 💾 **PersistentVolumes** - 持久卷

### 集群管理
- 🏷️ **Namespaces** - 命名空間
- 🖥️ **Nodes** - 節點信息
- ⚡ **Events** - 集群事件

## 🔐 安全說明

### 訪問令牌

- **位置**: `k8s-dashboard/dashboard-token.txt`
- **權限**: cluster-admin（完整權限）
- **有效期**: 10 年（87600 小時）
- **格式**: JWT Token

⚠️ **重要安全提示**:
1. 請妥善保管令牌文件
2. 不要將令牌提交到版本控制
3. 定期輪換令牌
4. 僅在可信網路中使用

### 重新生成令牌

```bash
vagrant ssh
kubectl -n kubernetes-dashboard create token admin-user --duration=87600h > /vagrant/k8s-dashboard/dashboard-token.txt
```

或生成短期令牌（1 小時）：
```bash
kubectl -n kubernetes-dashboard create token admin-user --duration=1h
```

## 🔍 故障排查

### 問題 1: 安裝失敗 - Kubernetes 未運行

**錯誤**: `kubectl: command not found`

**解決**:
```bash
vagrant ssh
sudo bash /vagrant/scripts/install-k8s.sh
```

### 問題 2: 無法訪問 Dashboard

**症狀**: 瀏覽器無法打開頁面

**檢查**:
```cmd
# 1. 檢查 kubectl proxy
vagrant ssh -c "ps aux | grep 'kubectl proxy'"

# 2. 檢查 Pod 狀態
vagrant ssh -c "kubectl get pods -n kubernetes-dashboard"
```

**解決**:
```cmd
stop-dashboard.bat
start-dashboard.bat
```

### 問題 3: 令牌無效

**症狀**: 登入提示 "Invalid token"

**解決**:
```bash
vagrant ssh
kubectl -n kubernetes-dashboard create token admin-user > /vagrant/k8s-dashboard/dashboard-token.txt
```

### 問題 4: Dashboard Pod 未就緒

**症狀**: Pod 狀態非 Running

**檢查**:
```bash
vagrant ssh
kubectl describe pod -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard
```

**解決**:
```bash
# 刪除 Pod 強制重啟
kubectl delete pod -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard
```

## 📖 使用指南

### 查看 Pod 列表

1. 登入 Dashboard
2. 左側菜單 → **Workloads** → **Pods**
3. 選擇命名空間（頂部下拉菜單）
4. 查看 Pod 列表

### 查看 Pod 日誌

1. 點擊 Pod 名稱
2. 點擊右上角 **Logs** 圖標
3. 選擇容器（如果有多個）
4. 查看實時日誌

### 進入容器終端

1. 點擊 Pod 名稱
2. 點擊右上角 **Exec** 圖標
3. 在終端中執行命令

### 管理 Deployments

1. 左側菜單 → **Workloads** → **Deployments**
2. 點擊部署名稱查看詳情
3. 右上角操作：
   - **Scale** - 調整副本數
   - **Edit** - 編輯配置
   - **Delete** - 刪除部署

### 創建 ConfigMap

1. 左側菜單 → **Config and Storage** → **Config Maps**
2. 點擊右上角 **Create**
3. 填寫名稱和數據
4. 點擊 **Deploy**

## 🔄 版本管理

### 當前版本

- **Dashboard**: v2.7.0
- **安裝包**: 1.0.0

### 升級 Dashboard

```bash
# 卸載舊版本
vagrant ssh -c "kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml"

# 安裝新版本（替換版本號）
vagrant ssh -c "kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v3.0.0/aio/deploy/recommended.yaml"
```

## 📚 參考資源

### 官方文檔
- [Kubernetes Dashboard 官網](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
- [GitHub 倉庫](https://github.com/kubernetes/dashboard)
- [發布說明](https://github.com/kubernetes/dashboard/releases)

### 本地文檔
- [完整使用指南](README.md)
- [詳細操作說明](../docs/K8S-DASHBOARD.md)
- [故障排查指南](../docs/TROUBLESHOOTING.md)

### 相關工具
- [kubectl 文檔](https://kubernetes.io/docs/reference/kubectl/)
- [Kubernetes 文檔](https://kubernetes.io/)

## 💡 最佳實踐

### 1. 安全訪問

- 僅在開發環境使用 admin-user
- 生產環境創建專用用戶並限制權限
- 使用 Ingress + TLS 替代 kubectl proxy

### 2. 資源管理

- 為命名空間設置資源配額
- 使用標籤組織資源
- 定期清理未使用的資源

### 3. 監控告警

- 安裝 metrics-server 查看資源使用
- 配置健康檢查
- 監控集群事件

## ✅ 驗證清單

安裝完成後驗證：

- [ ] Dashboard Pod 狀態為 Running
- [ ] kubectl proxy 正常啟動
- [ ] 瀏覽器可訪問 Dashboard
- [ ] 令牌可成功登入
- [ ] 可查看 Pod 列表
- [ ] 可查看日誌
- [ ] 可進入容器終端

驗證命令：
```cmd
# 檢查 Pod
vagrant ssh -c "kubectl get pods -n kubernetes-dashboard"

# 檢查服務
vagrant ssh -c "kubectl get svc -n kubernetes-dashboard"

# 測試訪問
start-dashboard.bat
```

## 📞 技術支持

### 常見問題

請先查看：
1. [k8s-dashboard/README.md](README.md)
2. [docs/K8S-DASHBOARD.md](../docs/K8S-DASHBOARD.md)
3. [docs/TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)

### 獲取幫助

- 執行 `access-dashboard.bat` 查看訪問信息
- 檢查 Pod 日誌定位問題
- 查看集群事件

---

**安裝包版本**: 1.0.0  
**Dashboard 版本**: v2.7.0  
**發布日期**: 2025-12-19  
**狀態**: ✅ 生產就緒

**完整的 Kubernetes Dashboard 管理頁面安裝包，可直接使用！**
