# scripts/

整合式 Shell 腳本目錄，每支腳本對應一個功能領域，以子命令方式操作。

## 目錄結構

```
scripts/
├── app.sh          應用程式管理（日誌、重建、重啟）
├── check.sh        狀態檢查與診斷
├── fix.sh          問題修復
├── setup.sh        環境安裝與初始設定
├── test.sh         功能測試
└── nginx/
    ├── nginx-test6.conf    Nginx 反向代理設定（含 LLM 330s 超時）
    └── update.sh           套用設定並重新載入 Nginx
```

---

## 使用方式

所有腳本皆支援子命令，不加參數執行即顯示說明：

```bash
bash /vagrant/scripts/<腳本>.sh
```

---

## app.sh — 應用程式管理

```bash
bash /vagrant/scripts/app.sh logs [N]   # 查看 App Pod 最後 N 行日誌（預設 80）
bash /vagrant/scripts/app.sh rebuild    # 強制重建 Pod（清除 JAR 鎖定）
bash /vagrant/scripts/app.sh restart    # 完整重啟（Maven 建置 → Redis flush → 重啟 Pod）
```

---

## check.sh — 狀態檢查與診斷

```bash
bash /vagrant/scripts/check.sh status    # 總覽：Pods + Ollama + Health + Chat 快測
bash /vagrant/scripts/check.sh network   # K8s 網路診斷（Flannel / CNI / subnet.env）
bash /vagrant/scripts/check.sh chat      # Kong 路由 + timeout + Chat API 測試
bash /vagrant/scripts/check.sh diag      # 詳細診斷：DNS → ClusterIP → Kong 全路徑
bash /vagrant/scripts/check.sh logs [N]  # App Pod 日誌（預設 80 行）
bash /vagrant/scripts/check.sh request   # 模擬對 Ollama 發出完整推理請求
bash /vagrant/scripts/check.sh frontend  # 前端 + Nginx AI timeout + ClusterIP 直連
```

---

## fix.sh — 問題修復

```bash
bash /vagrant/scripts/fix.sh flannel  # 修復 Flannel CNI（subnet.env 遺失）
bash /vagrant/scripts/fix.sh network  # 診斷並重建 App Pod 網路連線
bash /vagrant/scripts/fix.sh mysql    # 修復 MySQL springboot 用戶權限
bash /vagrant/scripts/fix.sh kong     # 修復 Kong app-service timeout 為 360s
bash /vagrant/scripts/fix.sh restart  # VM 重啟後一鍵恢復所有服務
```

---

## setup.sh — 環境安裝與設定

```bash
bash /vagrant/scripts/setup.sh docker       # 安裝 Docker Engine
bash /vagrant/scripts/setup.sh k8s-install  # 安裝 kubelet / kubeadm / kubectl
bash /vagrant/scripts/setup.sh k8s          # 初始化 K8s 叢集 + 安裝 Flannel
bash /vagrant/scripts/setup.sh kong         # 設定 Kong Gateway 路由
bash /vagrant/scripts/setup.sh frontend     # 安裝 Node.js + Nginx + 前端服務
bash /vagrant/scripts/setup.sh ollama       # 安裝 Ollama VM 直接模式 + 拉取模型
bash /vagrant/scripts/setup.sh ollama-path  # 修正 Ollama 模型路徑
bash /vagrant/scripts/setup.sh app-build    # 在 /tmp 重新編譯 JAR
bash /vagrant/scripts/setup.sh all          # 全套安裝
```

---

## test.sh — 功能測試

```bash
bash /vagrant/scripts/test.sh chat    # Chat API 測試（Streaming SSE + 同步 + Kong）
bash /vagrant/scripts/test.sh kong    # Kong Gateway 健康驗證
bash /vagrant/scripts/test.sh ollama  # Ollama 直連測試
bash /vagrant/scripts/test.sh e2e     # 端到端測試（預熱 → 推理 → Kong）
bash /vagrant/scripts/test.sh ai      # 完整 AI 路徑測試（含 JWT / 空訊息驗證）
```

---

## nginx/update.sh — 套用 Nginx 設定

```bash
bash /vagrant/scripts/nginx/update.sh  # 複製 nginx-test6.conf 並執行 nginx -t + reload
```

**nginx-test6.conf 已配置：**
- `/api/ai` → Kong，`proxy_read_timeout 330s`（LLM 推理用）
- `/api` → Kong，標準超時
- `/grafana` → Kong，WebSocket upgrade
- `/prometheus` → Kong
- `/` → frontend（port 3000）
