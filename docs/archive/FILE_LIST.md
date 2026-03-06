# 📦 Spring Boot 電商平台安裝包 - 文件清單

**版本**: 1.0.0  
**最後更新**: 2025-12-19  
**適用平台**: Windows 10/11

---

## 🗂️ 安裝包結構總覽

本安裝包已經完整整理，所有文件分類清晰，可直接使用。

### 📂 根目錄文件（核心配置）

| 文件 | 說明 | 重要性 |
|------|------|--------|
| `README.md` | 主要說明文檔（英文） | ⭐⭐⭐⭐⭐ |
| `README.zh-TW.md` | 中文完整說明 | ⭐⭐⭐⭐⭐ |
| `INSTALL_QUICK.md` | 快速安裝指南 | ⭐⭐⭐⭐⭐ |
| `install.bat` | 主安裝腳本 | ⭐⭐⭐⭐⭐ |
| `Vagrantfile` | Vagrant VM 配置 | ⭐⭐⭐⭐⭐ |
| `Dockerfile` | Docker 構建配置 | ⭐⭐⭐⭐⭐ |
| `docker-compose.yml` | 服務編排配置 | ⭐⭐⭐⭐⭐ |
| `docker-compose.dev.yml` | 開發環境配置 | ⭐⭐⭐ |
| `pom.xml` | Maven 配置 | ⭐⭐⭐⭐⭐ |
| `.dockerignore` | Docker 忽略規則 | ⭐⭐ |
| `.gitignore` | Git 忽略規則 | ⭐⭐ |

### � 根目錄文檔（新增）

| 文件 | 說明 | 適用場景 |
|------|------|----------|
| `PACKAGES_OVERVIEW.md` | 三合一安裝包總覽 | 了解完整安裝包結構 |

### 📚 docs/ - 文檔資料夾

| 文件 | 說明 | 適用場景 |
|------|------|----------|
| `QUICKSTART.md` | 快速開始指南 | 5 分鐘快速部署 |
| `INSTALL.md` | 完整安裝指南 | 詳細安裝步驟 |
| `DOCKER-GUIDE.md` | Docker 使用指南 | Docker 操作說明 |
| `DOCKER-ACCESS.md` | 容器訪問指南 | 進入容器調試 |
| `VAGRANT-GUIDE.md` | Vagrant 使用指南 | Vagrant 操作說明 |
| `TROUBLESHOOTING.md` | 故障排查指南 | 遇到問題時查閱 |
| `SHOPPING_API.md` | 購物 API 文檔 | API 開發參考 |
| `CHAT_API.md` | 聊天 API 文檔 | WebSocket API |
| `TEST_DATA.md` | 測試數據說明 | 測試數據參考 |
| `MYSQL_SETUP.md` | MySQL 配置說明 | 數據庫配置 |


### 🛠️ tools/ - 工具資料夾

#### 安裝工具
| 文件 | 說明 | 使用時機 |
|------|------|----------|
| `install-prerequisites.ps1` | 安裝 VirtualBox + Vagrant | 首次安裝前 |
| `check-requirements.bat` | 檢查前置需求 | 安裝前驗證 |
| `wait-for-app.bat` | 等待應用啟動 | 安裝後等待 |
| `verify-deployment.bat` | 驗證部署狀態 | 部署後驗證 |

#### Docker 管理工具
| 文件 | 說明 | 使用時機 |
|------|------|----------|
| `start-docker.bat` / `.sh` | 啟動 Docker 服務 | 啟動服務 |
| `rebuild-docker.bat` | 重建 Docker 映像 | 代碼更新後 |
| `fix-and-restart.bat` | 修復並重啟服務 | 服務異常時 |
| `docker-access.bat` | 訪問容器（互動式） | 容器調試 |

#### 診斷工具
| 文件 | 說明 | 使用時機 |
|------|------|----------|
| `diagnose.bat` | 系統診斷工具 | 遇到問題時 |
| `test-network.sh` | 網路連接測試 | 網路問題 |
| `test-integration.bat` | 整合測試 | 驗證功能 |
| `fix-docker-permission.sh` | 修復 Docker 權限 | 權限問題 |

### 💻 src/ - 源代碼資料夾

```
src/
├── main/
│   ├── java/com/example/demo/      # Java 源代碼
│   │   ├── DemoApplication.java    # 主程式
│   │   ├── config/                 # 配置類
│   │   ├── controller/             # 控制器
│   │   ├── model/                  # 數據模型
│   │   ├── repository/             # 數據訪問
│   │   ├── service/                # 業務邏輯
│   │   └── dto/                    # DTO 對象
│   └── resources/
│       ├── application.properties   # 配置文件
│       ├── application-mysql.properties  # MySQL 配置
│       └── static/                 # 靜態資源
└── test/                           # 測試代碼
```

### 🎨 frontend/ - 前端資料夾

```
frontend/
├── src/
│   ├── pages/                      # 頁面組件
│   │   ├── Shop.jsx               # 商城頁面
│   │   ├── Cart.jsx               # 購物車
│   │   ├── Orders.jsx             # 訂單管理
│   │   └── admin/                 # 後台管理
│   ├── components/                 # 通用組件
│   ├── services/                   # API 服務
│   └── stores/                     # 狀態管理
├── index.html                      # 入口 HTML
├── package.json                    # 依賴配置
└── vite.config.js                  # Vite 配置
```

### 📜 scripts/ - 安裝腳本資料夾

| 文件 | 說明 | 執行環境 |
|------|------|----------|
| `install-docker.sh` | Docker 安裝腳本 | Vagrant VM |
| `install-k8s.sh` | Kubernetes 安裝 | Vagrant VM |
| `setup-k8s-cluster.sh` | K8s 集群配置 | Vagrant VM |

### 🎛️ k8s-dashboard/ - K8s 管理頁面安裝包

| 文件 | 說明 | 使用時機 |
|------|------|----------|
| `install-dashboard.sh` | Dashboard 安裝腳本 | 首次安裝 |
| `install-dashboard.bat` | Windows 安裝腳本 | 首次安裝 |
| `start-dashboard.bat` | 啟動 Dashboard | 每次使用 |
| `stop-dashboard.bat` | 停止 Dashboard | 停止服務 |
| `access-dashboard.bat` | 訪問指南 | 查看訪問信息 |
| `uninstall-dashboard.sh` | 卸載 Dashboard | 移除時 |
| `README.md` | 詳細使用說明 | 完整文檔 |
| `dashboard-token.txt` | 訪問令牌（安裝後生成） | 登入使用 |

### 💾 data/ - 數據資料夾

存放數據庫初始化 SQL 腳本。

---

## 🚀 快速使用指南

### 新用戶（首次安裝）

1. **查看**: `README.zh-TW.md` 或 `INSTALL_QUICK.md`
2. **執行**: `tools\install-prerequisites.ps1`（管理員權限）
3. **執行**: `install.bat`
4. **執行**: `tools\verify-deployment.bat`

### 已安裝用戶

#### 啟動服務
```cmd
tools\start-docker.bat
```

#### 遇到問題
```cmd
tools\diagnose.bat
```

#### 重新構建
```cmd
tools\rebuild-docker.bat
```

---

## 📋 完整清單檢查表

### 核心文件 ✅
- [x] Dockerfile
- [x] docker-compose.yml
- [x] Vagrantfile
- [x] pom.xml
- [x] install.bat
- [x] README.md / README.zh-TW.md

### 文檔完整性 ✅
- [x] 快速開始指南 (INSTALL_QUICK.md, QUICKSTART.md)
- [x] 完整安裝指南 (INSTALL.md)
- [x] Docker 使用指南 (DOCKER-GUIDE.md)
- [x] 故障排查指南 (TROUBLESHOOTING.md)
- [x] API 文檔 (SHOPPING_API.md, CHAT_API.md)

### 工具完整性 ✅
- [x] 安裝工具 (install-prerequisites.ps1, check-requirements.bat)
- [x] 管理工具 (start-docker.bat, rebuild-docker.bat)
- [x] 診斷工具 (diagnose.bat, verify-deployment.bat)
- [x] 訪問工具 (docker-access.bat)

### 源代碼 ✅
- [x] Java 後端代碼 (src/)
- [x] React 前端代碼 (frontend/)
- [x] 測試代碼 (src/test/)

---

## 📊 文件統計

| 類型 | 數量 |
|------|------|
| 文檔文件 (.md) | 13 個 |
| Windows 工具 (.bat) | 10 個 |
| Linux 工具 (.sh) | 4 個 |
| PowerShell (.ps1) | 1 個 |
| 配置文件 | 6 個 |
| 源代碼目錄 | 2 個 |

---

## 🎯 重要提示

1. **不要刪除**根目錄的 Dockerfile、docker-compose.yml、Vagrantfile、pom.xml
2. **不要移動** src/ 和 frontend/ 資料夾
3. **推薦先閱讀** README.zh-TW.md 或 INSTALL_QUICK.md
4. **遇到問題**先運行 `tools\diagnose.bat`
5. **完整文檔**都在 docs/ 資料夾中

---

**此安裝包已完整整理，可直接分發使用！**
