# Kubernetes Dashboard 管理頁面安裝包

完整的 Kubernetes Dashboard 部署方案，支持一鍵安裝和訪問。

## 📦 安裝包內容

```
k8s-dashboard/
├── install-dashboard.sh        # Linux 安裝腳本
├── install-dashboard.bat       # Windows 安裝腳本
├── start-dashboard.bat         # 啟動 Dashboard
├── stop-dashboard.bat          # 停止 Dashboard
├── uninstall-dashboard.sh      # 卸載腳本
├── access-dashboard.bat        # 訪問指南
├── dashboard-token.txt         # 訪問令牌（安裝後生成）
└── README.md                   # 本文件
```

## � 如何登入 K8s 機器

如果需要在 Kubernetes 機器內執行命令，使用以下方式：

### Windows 登入方式

```cmd
# 在專案根目錄執行
cd c:\JOHNY\test
vagrant ssh
```

### 登入後的操作

登入成功後會看到提示符：
```
vagrant@k8s-master:~$
```

現在你在 Kubernetes 主節點內，可以執行：

```bash
# 查看集群狀態
kubectl get nodes
kubectl get pods -A
kubectl cluster-info

# 查看 Docker
docker ps
docker images

# 切換到共享目錄（專案文件）
cd /vagrant
ls -la
```

### 退出 VM

```bash
# 方式 1: 輸入 exit 命令
exit

# 方式 2: 按快捷鍵
Ctrl+D
```

---

## �🚀 快速開始

### 方式一：一鍵安裝（Windows）

```cmd
# 1. 安裝 Dashboard
cd k8s-dashboard
install-dashboard.bat

# 2. 啟動 Dashboard
start-dashboard.bat

# 3. 瀏覽器會自動打開，使用 dashboard-token.txt 中的令牌登入
```

### 方式二：手動安裝

#### 1. 進入 Vagrant VM

```cmd
vagrant ssh
```

#### 2. 執行安裝腳本

```bash
sudo bash /vagrant/k8s-dashboard/install-dashboard.sh
```

#### 3. 啟動 kubectl proxy

```bash
kubectl proxy --address='0.0.0.0' --accept-hosts='.*'
```

#### 4. 在 Windows 瀏覽器訪問

```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

#### 5. 取得並使用令牌登入

##### 🔑 方式一：查看 token 文件（最簡單）

**在 Windows 執行**：
```cmd
# 查看 token 內容
type k8s-dashboard\dashboard-token.txt

# 或使用 PowerShell
Get-Content k8s-dashboard\dashboard-token.txt

# 或用記事本打開
notepad k8s-dashboard\dashboard-token.txt
```

**Token 文件位置**：`c:\JOHNY\test\k8s-dashboard\dashboard-token.txt`

##### 🔑 方式二：在 VM 內查詢

**在 VM 內執行**：
```bash
# 登入 VM
vagrant ssh

# 查看 token
cat /vagrant/k8s-dashboard/dashboard-token.txt

# 或使用 kubectl 重新獲取
kubectl -n kubernetes-dashboard create token admin-user
```

##### 📝 如何使用 Token 登入

1. **打開 Dashboard 網址**：
   ```
   http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
   ```

2. **選擇登入方式**：
   - 點選 **"Token"** 選項（預設）

3. **複製 Token**：
   - 打開 `dashboard-token.txt` 文件
   - 複製全部內容（很長的一串字）
   - **注意**：複製完整的 token，不要有空格或換行

4. **貼上 Token**：
   - 在登入頁面的 "Enter token" 欄位貼上
   - 點擊 **"Sign in"** 按鈕

5. **登入成功**：
   - 會看到 Kubernetes Dashboard 主頁面
   - 可以查看 Pods、Services、Deployments 等

##### ⚠️ Token 注意事項

- **有效期**：10 年（87600 小時）
- **權限**：cluster-admin（完整管理權限）
- **安全**：請妥善保管，不要分享給他人

## 📋 前置需求

### 必須安裝
- ✅ VirtualBox 7.0+
- ✅ Vagrant 2.4+
- ✅ Kubernetes 集群（使用 `scripts/install-k8s.sh` 安裝）

### 確認 Kubernetes 運行

```bash
vagrant ssh -c "kubectl get nodes"
```

應該看到節點狀態為 `Ready`。

## 🛠️ 詳細說明

### 安裝流程

`install-dashboard.sh` 執行以下步驟：

1. **檢查環境**
   - 驗證 kubectl 是否安裝
   - 驗證 Kubernetes 集群是否運行

2. **部署 Dashboard**
   - 應用官方 Dashboard 配置
   - 部署到 `kubernetes-dashboard` 命名空間

3. **創建管理員用戶**
   - 創建 ServiceAccount: `admin-user`
   - 綁定 cluster-admin 角色

4. **生成訪問令牌**
   - 創建長期有效令牌（10 年）
   - 保存到 `dashboard-token.txt`

### Dashboard 版本

- **Kubernetes Dashboard**: v2.7.0
- **支持的 Kubernetes 版本**: 1.21+

### 端口配置

- **kubectl proxy**: 8001
- **Dashboard 服務**: 443 (HTTPS)

## 🔐 安全說明

### 令牌管理

1. **令牌位置**: `k8s-dashboard/dashboard-token.txt`
2. **權限**: 600 (僅所有者可讀)
3. **有效期**: 10 年（87600 小時）
4. **作用域**: cluster-admin（完整權限）

⚠️ **重要**: 請妥善保管令牌，它擁有集群的完整管理權限！

### 訪問控制

Dashboard 僅通過 kubectl proxy 訪問，預設配置：
- 監聽地址: `0.0.0.0`（允許外部訪問）
- 允許所有主機: `.*`

生產環境建議修改為更嚴格的配置。

## 📊 常用命令

### 查看 Dashboard 狀態

```bash
# 查看 Pod 狀態
vagrant ssh -c "kubectl get pods -n kubernetes-dashboard"

# 查看服務狀態
vagrant ssh -c "kubectl get svc -n kubernetes-dashboard"

# 查看部署狀態
vagrant ssh -c "kubectl get deployment -n kubernetes-dashboard"
```

### 查看 Dashboard 日誌

```bash
vagrant ssh -c "kubectl logs -f -n kubernetes-dashboard deployment/kubernetes-dashboard"
```

### 重新生成令牌

```bash
vagrant ssh -c "kubectl -n kubernetes-dashboard create token admin-user --duration=87600h"
```

### 刪除舊令牌（如果需要）

```bash
# 列出所有 Secret
vagrant ssh -c "kubectl get secrets -n kubernetes-dashboard"

# 刪除特定 Secret
vagrant ssh -c "kubectl delete secret <secret-name> -n kubernetes-dashboard"
```

## 🔧 故障排查

### 問題 1: 無法訪問 Dashboard

**症狀**: 瀏覽器顯示無法連接

**解決方案**:
```bash
# 檢查 kubectl proxy 是否運行
vagrant ssh -c "ps aux | grep 'kubectl proxy'"

# 重新啟動 proxy
vagrant ssh -c "kubectl proxy --address='0.0.0.0' --accept-hosts='.*'"
```

### 問題 2: 令牌無效

**症狀**: 登入時提示 "Invalid token"

**解決方案**:
```bash
# 重新生成令牌
vagrant ssh -c "kubectl -n kubernetes-dashboard create token admin-user --duration=87600h > /vagrant/k8s-dashboard/dashboard-token.txt"
```

### 問題 3: Dashboard Pod 未啟動

**症狀**: Pod 狀態為 Pending 或 CrashLoopBackOff

**解決方案**:
```bash
# 查看 Pod 詳情
vagrant ssh -c "kubectl describe pod -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard"

# 查看事件
vagrant ssh -c "kubectl get events -n kubernetes-dashboard"

# 重新部署
vagrant ssh -c "kubectl delete pod -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard"
```

### 問題 4: Vagrant 端口衝突

**症狀**: kubectl proxy 無法啟動，提示端口 8001 被佔用

**解決方案**:
```powershell
# 查找佔用端口的進程
netstat -ano | findstr :8001

# 結束進程（替換 <PID>）
taskkill /PID <PID> /F
```

## 📱 訪問方式

### 方式 1: kubectl proxy（推薦）

```bash
kubectl proxy --address='0.0.0.0' --accept-hosts='.*'
```

訪問地址: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

### 方式 2: NodePort（需要額外配置）

修改 Dashboard Service 類型為 NodePort：

```bash
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type":"NodePort"}}'
```

查看分配的端口：

```bash
kubectl get svc kubernetes-dashboard -n kubernetes-dashboard
```

訪問: https://192.168.10.10:<NodePort>

### 方式 3: Port Forward

```bash
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8443:443 --address 0.0.0.0
```

訪問: https://localhost:8443

## 🎯 Dashboard 功能

### 概覽儀表板
- 集群資源使用情況
- Pod 狀態統計
- 工作負載健康狀況

### 工作負載管理
- **Deployments**: 查看和管理部署
- **ReplicaSets**: 副本集管理
- **Pods**: Pod 詳情和日誌
- **Jobs/CronJobs**: 任務調度

### 服務與網路
- **Services**: 服務列表
- **Ingress**: 入口規則
- **Network Policies**: 網路策略

### 存儲
- **PersistentVolumes**: 持久卷
- **PersistentVolumeClaims**: PVC 管理
- **StorageClasses**: 存儲類別

### 配置
- **ConfigMaps**: 配置映射
- **Secrets**: 密鑰管理

### 集群管理
- **Namespaces**: 命名空間
- **Nodes**: 節點信息
- **Events**: 集群事件

## 🔄 更新 Dashboard

### 升級到新版本

```bash
# 卸載舊版本
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# 安裝新版本（替換版本號）
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v3.0.0/aio/deploy/recommended.yaml
```

## 🗑️ 卸載 Dashboard

### Windows

```cmd
vagrant ssh -c "sudo bash /vagrant/k8s-dashboard/uninstall-dashboard.sh"
```

### Linux

```bash
sudo bash /vagrant/k8s-dashboard/uninstall-dashboard.sh
```

## 📚 參考資源

- [官方文檔](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
- [GitHub 倉庫](https://github.com/kubernetes/dashboard)
- [版本發布](https://github.com/kubernetes/dashboard/releases)

## 📄 許可證

本安裝包遵循 MIT 許可證。

Kubernetes Dashboard 本身遵循 Apache 2.0 許可證。

---

**Version**: 1.0.0  
**Dashboard Version**: v2.7.0  
**Last Updated**: 2025-12-19
