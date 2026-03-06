# 📦 Spring Boot 電商平台 - 完整安裝包總覽

**版本**: 1.0.0  
**發布日期**: 2025-12-19  
**適用平台**: Windows 10/11

---

## 🎯 安裝包概述

本專案包含**三個完整的安裝包**，可獨立或組合使用：

### 1️⃣ Docker 容器化部署包（主要）
### 2️⃣ Kubernetes Dashboard 管理頁面包
### 3️⃣ 完整文檔與工具包

---

## 📦 安裝包詳細說明

### 1. 🐳 Docker 容器化部署包

**目的**: 部署完整的 Spring Boot 電商應用（MySQL + Redis + App）

**位置**: 根目錄 + `tools/` 資料夾

**包含內容**:
```
根目錄/
├── Dockerfile                      # Docker 構建文件
├── docker-compose.yml              # 服務編排
├── Vagrantfile                     # VM 配置
├── pom.xml                         # Maven 配置
└── install.bat                     # 主安裝腳本

tools/
├── install-prerequisites.ps1       # 前置軟體安裝
├── start-docker.bat                # 啟動服務
├── rebuild-docker.bat              # 重建容器
├── docker-access.bat               # 訪問容器
├── diagnose.bat                    # 診斷工具
└── verify-deployment.bat           # 驗證部署
```

**快速開始**:
```cmd
# 1. 安裝前置軟體（管理員權限）
.\tools\install-prerequisites.ps1

# 2. 部署應用
.\install.bat

# 3. 驗證部署
.\tools\verify-deployment.bat
```

**訪問服務**:
- **主應用**: http://localhost:8080
- **API 文檔**: http://localhost:8080/swagger-ui.html
- **健康檢查**: http://localhost:8080/actuator/health
- **MySQL**: localhost:3307
- **Redis**: localhost:6379

**技術棧**:
- Spring Boot 3.2.0
- MySQL 8.0
- Redis 7
- Docker + Docker Compose
- Vagrant + VirtualBox

**文檔**:
- [INSTALL_QUICK.md](INSTALL_QUICK.md) - 快速安裝
- [docs/DOCKER-GUIDE.md](docs/DOCKER-GUIDE.md) - Docker 使用指南
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - 故障排查

---

### 2. 🎛️ Kubernetes Dashboard 管理頁面包

**目的**: 提供 Web 圖形界面管理 Kubernetes 集群

**位置**: `k8s-dashboard/` 資料夾

**包含內容**:
```
k8s-dashboard/
├── install-dashboard.sh            # Linux 安裝腳本
├── install-dashboard.bat           # Windows 安裝腳本
├── start-dashboard.bat             # 啟動 Dashboard
├── stop-dashboard.bat              # 停止 Dashboard
├── access-dashboard.bat            # 訪問信息
├── uninstall-dashboard.sh          # 卸載腳本
├── README.md                       # 完整使用說明
├── PACKAGE_INFO.md                 # 安裝包詳情
└── dashboard-token.txt             # 訪問令牌（安裝後生成）
```

**快速開始**:
```cmd
cd k8s-dashboard
install-dashboard.bat    # 安裝
start-dashboard.bat      # 啟動
```

**訪問地址**:
```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

**Dashboard 功能**:
- 📊 集群資源監控
- 🚀 Pods、Deployments、Services 管理
- 📝 實時日誌查看
- 💻 容器終端訪問
- ⚙️ ConfigMaps、Secrets 管理
- 💾 PersistentVolumes 管理
- 🏷️ 命名空間管理

**前置需求**:
- ✅ Kubernetes 集群已安裝（使用 `scripts/install-k8s.sh`）
- ✅ Vagrant VM 運行中

**文檔**:
- [k8s-dashboard/README.md](k8s-dashboard/README.md) - 完整使用說明
- [k8s-dashboard/PACKAGE_INFO.md](k8s-dashboard/PACKAGE_INFO.md) - 安裝包詳情
- [docs/K8S-DASHBOARD.md](docs/K8S-DASHBOARD.md) - 詳細操作指南

**Dashboard 版本**: v2.7.0

---

### 3. 📚 完整文檔與工具包

**目的**: 提供詳細的使用說明、API 文檔和診斷工具

**位置**: `docs/` 和 `tools/` 資料夾

**文檔內容**:
```
docs/                               # 11 個文檔
├── QUICKSTART.md                   # 快速開始指南
├── INSTALL.md                      # 完整安裝指南
├── DOCKER-GUIDE.md                 # Docker 使用
├── DOCKER-ACCESS.md                # 容器訪問
├── VAGRANT-GUIDE.md                # Vagrant 使用
├── K8S-DASHBOARD.md                # K8s Dashboard 指南
├── TROUBLESHOOTING.md              # 故障排查
├── SHOPPING_API.md                 # 購物 API
├── CHAT_API.md                     # 聊天 API
├── TEST_DATA.md                    # 測試數據
└── MYSQL_SETUP.md                  # MySQL 配置
```

**工具內容**:
```
tools/                              # 13 個工具
├── 安裝工具
│   ├── install-prerequisites.ps1   # 前置軟體安裝
│   ├── check-requirements.bat      # 檢查需求
│   └── wait-for-app.bat            # 等待啟動
│
├── Docker 管理
│   ├── start-docker.bat            # 啟動服務
│   ├── rebuild-docker.bat          # 重建容器
│   ├── fix-and-restart.bat         # 修復重啟
│   └── docker-access.bat           # 訪問容器
│
└── 診斷工具
    ├── diagnose.bat                # 系統診斷
    ├── verify-deployment.bat       # 驗證部署
    ├── test-integration.bat        # 整合測試
    └── test-network.sh             # 網路測試
```

---

## 🚀 完整安裝流程

### 情境 1: 僅使用 Docker 部署應用

```cmd
# 1. 安裝前置軟體
.\tools\install-prerequisites.ps1

# 2. 部署應用
.\install.bat

# 3. 訪問應用
# http://localhost:8080
```

### 情境 2: Docker + Kubernetes Dashboard

```cmd
# 1. 部署應用（同上）
.\tools\install-prerequisites.ps1
.\install.bat

# 2. 安裝 Kubernetes（如未安裝）
vagrant ssh
sudo bash /vagrant/scripts/install-k8s.sh
exit

# 3. 安裝 K8s Dashboard
cd k8s-dashboard
install-dashboard.bat
start-dashboard.bat

# 4. 訪問 Dashboard
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

### 情境 3: 完整環境（推薦學習）

1. **部署應用** → Docker 容器化
2. **安裝 Kubernetes** → 容器編排
3. **安裝 Dashboard** → Web 管理界面
4. **查閱文檔** → 深入了解各功能

---

## 📋 系統需求

### 硬體需求
- **CPU**: 雙核心 2.0 GHz 以上
- **記憶體**: 8 GB RAM（推薦 16 GB）
- **硬碟**: 20 GB 可用空間

### 軟體需求
- **作業系統**: Windows 10/11 (64-bit)
- **VirtualBox**: 7.0+
- **Vagrant**: 2.4+
- **瀏覽器**: Chrome/Firefox/Edge（最新版本）

---

## 📊 功能對照表

| 功能 | Docker 部署包 | K8s Dashboard 包 | 文檔工具包 |
|------|--------------|-----------------|-----------|
| Spring Boot 應用 | ✅ | ❌ | 📖 |
| MySQL 資料庫 | ✅ | ❌ | 📖 |
| Redis 緩存 | ✅ | ❌ | 📖 |
| Kubernetes 集群 | ❌ | ✅ 需要 | 📖 |
| Web 管理界面 | ❌ | ✅ | 📖 |
| Pod 管理 | ❌ | ✅ | 📖 |
| 日誌查看 | ✅ CLI | ✅ Web | 📖 |
| 容器訪問 | ✅ | ✅ | 📖 |
| API 文檔 | ✅ | ❌ | ✅ |
| 故障診斷 | ✅ | ✅ | ✅ |

---

## 🔍 快速索引

### 我想...

**部署應用**
→ 查看 [INSTALL_QUICK.md](INSTALL_QUICK.md)

**使用 Docker**
→ 查看 [docs/DOCKER-GUIDE.md](docs/DOCKER-GUIDE.md)

**管理 Kubernetes**
→ 查看 [k8s-dashboard/README.md](k8s-dashboard/README.md)

**查看 API**
→ 查看 [docs/SHOPPING_API.md](docs/SHOPPING_API.md)

**解決問題**
→ 查看 [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

**了解專案結構**
→ 查看 [FILE_LIST.md](FILE_LIST.md)

**查看整理記錄**
→ 查看 [CLEANUP_REPORT.md](CLEANUP_REPORT.md)

---

## 📞 技術支持

### 診斷工具

```cmd
# Docker 相關問題
.\tools\diagnose.bat

# K8s Dashboard 問題
cd k8s-dashboard
access-dashboard.bat
```

### 常見問題

1. **應用無法訪問** → 查看 [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. **Dashboard 無法連接** → 查看 [k8s-dashboard/README.md](k8s-dashboard/README.md)
3. **容器啟動失敗** → 執行 `.\tools\diagnose.bat`

---

## 📄 文件清單

### 根目錄核心文件（13 個）
- README.md / README.zh-TW.md
- INSTALL_QUICK.md
- FILE_LIST.md
- CLEANUP_REPORT.md
- Dockerfile / docker-compose.yml
- Vagrantfile / pom.xml
- install.bat

### docs/ 文檔（13 個）
完整的使用說明、API 文檔、故障排查指南

### tools/ 工具（13 個）
安裝、管理、診斷工具

### k8s-dashboard/ K8s 管理包（9 個）
完整的 Kubernetes Dashboard 安裝包

**總計**: 約 50 個文件，結構清晰，功能完整

---

## ✅ 品質保證

### 測試環境
- ✅ Windows 10/11
- ✅ VirtualBox 7.0
- ✅ Vagrant 2.4
- ✅ Docker + Docker Compose
- ✅ Kubernetes 1.28

### 驗證項目
- ✅ 一鍵安裝流程
- ✅ 應用正常運行
- ✅ 所有服務健康
- ✅ API 可正常訪問
- ✅ Dashboard 可正常登入
- ✅ 文檔完整準確

---

## 🎉 總結

**三合一完整安裝包**:

1. **Docker 部署包** - 快速部署 Spring Boot 應用
2. **K8s Dashboard 包** - Web 圖形界面管理
3. **文檔工具包** - 完整的使用說明和工具

**適用場景**:
- ✅ 學習 Spring Boot 開發
- ✅ 學習 Docker 容器化
- ✅ 學習 Kubernetes 編排
- ✅ 開發測試環境搭建
- ✅ 微服務架構實踐

**立即開始**:
```cmd
.\tools\install-prerequisites.ps1
.\install.bat
```

---

**版本**: 1.0.0  
**最後更新**: 2025-12-19  
**狀態**: ✅ 生產就緒，可直接使用

**完整的一站式解決方案！**
