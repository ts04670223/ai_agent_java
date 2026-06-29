# -*- mode: ruby -*-
# vi: set ft=ruby :

# Kubernetes Development Environment on Vagrant with Docker
Vagrant.configure("2") do |config|
  # 使用 Ubuntu 20.04 LTS (Kubernetes 相容性較好)
  config.vm.box = "ubuntu/focal64"
  
  # 配置虛擬機名稱和資源
  # config.vm.provider "virtualbox" do |vb|
  #   vb.name = "k8s-dev-environment"
  #   vb.memory = "8192"  # K8s 需要至少 2GB，建議 4GB
  #   vb.cpus = 4
  # end
  config.vm.provider "virtualbox" do |vb|
    vb.name = "k8s-test-new"
    vb.memory = "8192"  # K8s 需要至少 2GB，建議 4GB
    vb.cpus = 4
  end
  
  # 配置主機名稱
  # config.vm.hostname = "k8s-master"
  config.vm.hostname = "k8s-test-new"
  
  # 配置網路
  config.vm.network "private_network", ip: "192.168.10.10"
  
  # 端口轉發
  config.vm.network "forwarded_port", guest: 6443, host: 6443   # K8s API Server
  config.vm.network "forwarded_port", guest: 9443, host: 9443   # K8s Dashboard (HTTPS)
  config.vm.network "forwarded_port", guest: 8080, host: 8080   # Spring Boot App
  config.vm.network "forwarded_port", guest: 3307, host: 3307   # MySQL
  config.vm.network "forwarded_port", guest: 6379, host: 6379   # Redis
  config.vm.network "forwarded_port", guest: 80, host: 80       # HTTP
  config.vm.network "forwarded_port", guest: 443, host: 8443    # HTTPS
  config.vm.network "forwarded_port", guest: 30000, host: 30000 # NodePort起始
  config.vm.network "forwarded_port", guest: 30080, host: 30080 # Spring Boot NodePort
  config.vm.network "forwarded_port", guest: 30090, host: 30090 # Prometheus
  config.vm.network "forwarded_port", guest: 30300, host: 30300 # Grafana
  
  # 同步資料夾
  config.vm.synced_folder ".", "/vagrant"
  
  # 執行安裝腳本（使用整合式腳本 scripts/setup.sh）
  config.vm.provision "shell", name: "install-docker",
    inline: "bash /vagrant/scripts/setup.sh docker"
  config.vm.provision "shell", name: "install-k8s",
    inline: "bash /vagrant/scripts/setup.sh k8s-install"
  config.vm.provision "shell", name: "setup-k8s-cluster",
    inline: "bash /vagrant/scripts/setup.sh k8s"
  # 修復 kubelet hostname 不匹配 + subnet.env 開機自動建立
  config.vm.provision "shell", name: "fix-kubelet-hostname", inline: <<-SHELL
    # VM hostname 為 k8s-test-new，但 kubeadm init 時節點註冊為 k8s-master
    # 加入 --hostname-override 讓 kubelet 正確對應節點名稱
    if ! grep -q "hostname-override" /var/lib/kubelet/kubeadm-flags.env 2>/dev/null; then
      CURRENT_ARGS=$(cat /var/lib/kubelet/kubeadm-flags.env 2>/dev/null | sed 's/KUBELET_KUBEADM_ARGS="//;s/"$//')
      echo "KUBELET_KUBEADM_ARGS=\"--hostname-override=k8s-master ${CURRENT_ARGS}\"" \
        > /var/lib/kubelet/kubeadm-flags.env
      systemctl restart kubelet
      echo "kubelet hostname-override=k8s-master 已設定"
    fi

    # 建立 systemd oneshot 服務：開機時自動建立 /run/flannel/subnet.env
    # （/run 是 tmpfs，每次重啟後消失）
    cat > /usr/local/bin/create-flannel-subnet-env.sh << 'EOF'
#!/bin/bash
mkdir -p /run/flannel
cat > /run/flannel/subnet.env << SUBNET
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.0.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true
SUBNET
EOF
    chmod +x /usr/local/bin/create-flannel-subnet-env.sh

    cat > /etc/systemd/system/flannel-subnet-env.service << 'EOF'
[Unit]
Description=Create Flannel subnet.env in /run (tmpfs)
Before=kubelet.service
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/create-flannel-subnet-env.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable flannel-subnet-env.service
    systemctl start flannel-subnet-env.service
    echo "flannel-subnet-env.service 已啟用（開機自動建立 subnet.env）"
  SHELL

  config.vm.provision "shell", name: "setup-frontend",
    inline: "bash /vagrant/scripts/setup.sh frontend"
  config.vm.provision "shell", name: "install-ollama",
    inline: "bash /vagrant/scripts/setup.sh ollama"

  # 部署基礎 K8s 服務（MySQL、Redis、Kong）
  config.vm.provision "shell", name: "deploy-k8s-services", privileged: false, inline: <<-SHELL
    echo "=== 建立 K8s Secrets ==="
    kubectl create secret generic app-secret \
      --from-literal=db-username=springboot \
      --from-literal=db-password=springboot123 \
      --from-literal=jwt-secret=my-jwt-secret-key-for-spring-boot-demo-application \
      --dry-run=client -o yaml | kubectl apply -f -

    echo "=== 部署 MySQL ==="
    kubectl apply -f /vagrant/mysql-claim1-persistentvolumeclaim.yaml
    kubectl apply -f /vagrant/mysql-data-persistentvolumeclaim.yaml
    kubectl apply -f /vagrant/mysql-deployment.yaml
    kubectl apply -f /vagrant/mysql-service.yaml

    echo "=== 部署 Redis ==="
    kubectl apply -f /vagrant/redis-data-persistentvolumeclaim.yaml
    kubectl apply -f /vagrant/redis-deployment.yaml
    kubectl apply -f /vagrant/redis-service.yaml

    echo "=== 部署 Kong ==="
    kubectl apply -f /vagrant/kong/kong-k8s.yaml

    echo "=== 部署 Kubernetes Dashboard ==="
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml 2>/dev/null || true

    echo "=== 等待基礎服務就緒 ==="
    kubectl wait --for=condition=ready pod -l io.kompose.service=mysql --timeout=180s 2>/dev/null \
      || echo "MySQL 尚未就緒（將繼續）"
    kubectl wait --for=condition=ready pod -l io.kompose.service=redis --timeout=120s 2>/dev/null \
      || echo "Redis 尚未就緒（將繼續）"

    echo "=== 修復 MySQL 用戶權限 ==="
    sleep 10
    kubectl exec deployment/mysql -- mysql -uroot -prootpassword -e \
      "CREATE USER IF NOT EXISTS 'springboot'@'%' IDENTIFIED BY 'springboot123'; GRANT ALL PRIVILEGES ON spring_boot_demo.* TO 'springboot'@'%'; FLUSH PRIVILEGES;" \
      2>/dev/null || echo "MySQL 權限稍後手動修復: bash /vagrant/scripts/fix.sh mysql"

    echo "=== 建立 Dashboard admin-user 並產生 Token ==="
    kubectl create serviceaccount admin-user -n kubernetes-dashboard 2>/dev/null || true
    kubectl create clusterrolebinding admin-user \
      --clusterrole=cluster-admin \
      --serviceaccount=kubernetes-dashboard:admin-user 2>/dev/null || true
    TOKEN=$(kubectl -n kubernetes-dashboard create token admin-user --duration=8760h 2>/dev/null)
    if [ -n "$TOKEN" ]; then
      echo "$TOKEN" > /vagrant/k8s-dashboard/dashboard-token.txt
      echo "✓ Dashboard Token 已更新至 k8s-dashboard/dashboard-token.txt"
    fi

    echo "=== 基礎服務部署完成 ==="
    kubectl get pods --no-headers
  SHELL

  # Redis port-forward：讓 VM 上的 java -jar app 可用 localhost:6379 連到 K8s Redis
  config.vm.provision "shell", inline: <<-SHELL
    cat > /etc/systemd/system/redis-portforward.service << 'EOF'
[Unit]
Description=kubectl port-forward for Redis (K8s -> localhost:6379)
After=network.target kubelet.service
Requires=kubelet.service

[Service]
Type=simple
User=vagrant
Environment=KUBECONFIG=/home/vagrant/.kube/config
ExecStart=/usr/bin/kubectl port-forward svc/redis 6379:6379 --address=0.0.0.0
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable redis-portforward.service
    # 等待 Redis Pod 就緒後再啟動 port-forward
    export KUBECONFIG=/home/vagrant/.kube/config
    echo "等待 Redis Pod 就緒..."
    kubectl wait --for=condition=ready pod -l io.kompose.service=redis --timeout=120s 2>/dev/null \
      || echo "Redis Pod 尚未就緒，port-forward 將在 Pod 就緒後由 systemd 自動重試"
    systemctl restart redis-portforward.service
    echo "Redis port-forward service started (0.0.0.0:6379 -> K8s redis:6379)"
  SHELL

  # 配置 Kong 路由
  config.vm.provision "shell", name: "setup-kong", inline: <<-SHELL
    export KUBECONFIG=/home/vagrant/.kube/config
    echo "等待 Kong Pod 就緒..."
    kubectl wait --for=condition=ready pod -l io.kompose.service=kong --timeout=180s 2>/dev/null \
      || echo "Kong Pod 尚未就緒，嘗試繼續..."
    
    echo "等待 Kong Admin API 可連線..."
    KONG_ADMIN="http://192.168.10.10:30003"
    for i in $(seq 1 30); do
      if curl -s -f "${KONG_ADMIN}" > /dev/null 2>&1; then
        echo "Kong Admin API 就緒！"
        bash /vagrant/scripts/setup.sh kong
        exit 0
      fi
      echo "  嘗試 $i/30 - Kong Admin API 尚未就緒，等待 10 秒..."
      sleep 10
    done
    echo "⚠ Kong Admin API 等待超時，稍後可手動執行: bash /vagrant/scripts/setup.sh kong"
  SHELL
  
  # 創建 Dashboard 啟動腳本和 systemd 服務
  config.vm.provision "shell", inline: <<-SHELL
    # 創建啟動腳本
    cat > /usr/local/bin/start-dashboard-forward.sh << 'EOF'
#!/bin/bash
export KUBECONFIG=/home/vagrant/.kube/config
while true; do
  kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard 9443:443 --address=0.0.0.0
  echo "Dashboard port-forward 已停止，5秒後重新啟動..."
  sleep 5
done
EOF
    chmod +x /usr/local/bin/start-dashboard-forward.sh
    
    # 創建 systemd 服務文件
    cat > /etc/systemd/system/k8s-dashboard-forward.service << 'EOF'
[Unit]
Description=Kubernetes Dashboard Port Forward
After=network.target

[Service]
Type=simple
User=vagrant
Environment="KUBECONFIG=/home/vagrant/.kube/config"
ExecStart=/usr/local/bin/start-dashboard-forward.sh
Restart=always
RestartSec=10
StandardOutput=append:/tmp/dashboard-forward.log
StandardError=append:/tmp/dashboard-forward.log

[Install]
WantedBy=multi-user.target
EOF
    
    # 只停止舊的 Dashboard port-forward（不影響 Redis port-forward）
    pkill -f "port-forward.*dashboard" || true
    
    # 等待 Dashboard Pod 就緒
    export KUBECONFIG=/home/vagrant/.kube/config
    echo "等待 Dashboard Pod 就緒..."
    kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=120s 2>/dev/null \
      || echo "Dashboard Pod 尚未就緒，port-forward 將在 Pod 就緒後由 systemd 自動重試"
    
    # 啟用並啟動服務
    systemctl daemon-reload
    systemctl enable k8s-dashboard-forward.service
    systemctl restart k8s-dashboard-forward.service
    
    sleep 3
    echo "Kubernetes Dashboard Port Forward 服務已啟動"
    echo "存取網址: https://192.168.10.10:9443/"
    echo "日誌位置: /tmp/dashboard-forward.log"
    echo "服務狀態: systemctl status k8s-dashboard-forward"
  SHELL

  # 建立 Spring Boot JAR → Docker image → 部署至 K8s
  config.vm.provision "shell", name: "build-and-deploy-app", privileged: false, inline: <<-SHELL
    echo "=== 建立 Docker image ==="
    cd /vagrant && docker build -t vagrant-app:latest -f Dockerfile.bak . 2>&1 | tail -5
    echo "=== 匯入 image 到 containerd (K8s) ==="
    docker save vagrant-app:latest > /tmp/vagrant-app.tar
    sudo ctr -n k8s.io images import /tmp/vagrant-app.tar
    rm -f /tmp/vagrant-app.tar
    echo "=== 部署 app 到 K8s ==="
    kubectl apply -f /vagrant/app-deployment.yaml
    kubectl apply -f /vagrant/app-service.yaml
    echo "=== 等待 App Pod Ready ==="
    kubectl wait --for=condition=ready pod -l io.kompose.service=app --timeout=300s \
      || echo "⚠ App 尚未就緒，可能仍在啟動中"
    echo "Spring Boot app 已部署到 K8s (JAR 從 /vagrant/target 掛載)"
  SHELL

  # 最終驗證：確認所有服務可連線
  config.vm.provision "shell", name: "verify-services", privileged: false, inline: <<-SHELL
    echo "=================================="
    echo "  服務連線驗證"
    echo "=================================="
    PASS=0; FAIL=0

    # 檢查 Node Ready
    NODE_STATUS=$(kubectl get node k8s-master -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    if [ "$NODE_STATUS" = "True" ]; then
      echo "✓ Node k8s-master: Ready"; PASS=$((PASS+1))
    else
      echo "✗ Node k8s-master: NotReady"; FAIL=$((FAIL+1))
    fi

    # 檢查 Pod 狀態
    for SVC in mysql redis kong app; do
      POD_READY=$(kubectl get pods -l io.kompose.service=$SVC -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
      if [ "$POD_READY" = "True" ]; then
        echo "✓ Pod $SVC: Ready"; PASS=$((PASS+1))
      else
        echo "✗ Pod $SVC: NotReady"; FAIL=$((FAIL+1))
      fi
    done

    # 檢查 App endpoints（Kong DNS 解析依賴）
    EP_COUNT=$(kubectl get endpoints app -o jsonpath='{.subsets[0].addresses}' 2>/dev/null | grep -c "ip" || echo "0")
    if [ "$EP_COUNT" -gt 0 ]; then
      echo "✓ Endpoints app: $EP_COUNT 個地址（Kong DNS 可解析）"; PASS=$((PASS+1))
    else
      echo "✗ Endpoints app: 無就緒地址（Kong 將出現 DNS resolve 錯誤）"; FAIL=$((FAIL+1))
    fi

    # 檢查 HTTP 端點
    check_http() {
      local NAME=$1 URL=$2
      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL" --max-time 5 --insecure 2>/dev/null || echo "000")
      if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ]; then
        echo "✓ $NAME: HTTP $HTTP_CODE"; PASS=$((PASS+1))
      else
        echo "✗ $NAME: HTTP $HTTP_CODE"; FAIL=$((FAIL+1))
      fi
    }
    check_http "Kong API (/api/products)" "http://192.168.10.10:30000/api/products"
    check_http "Kong Admin (30003)" "http://192.168.10.10:30003/"
    check_http "Frontend (443/HTTPS)" "https://localhost:443/"
    check_http "Ollama (11434)" "http://localhost:11434/api/tags"

    # 檢查 containerd image 存在
    if sudo ctr -n k8s.io images ls | grep -q "vagrant-app"; then
      echo "✓ containerd image: vagrant-app:latest 存在"; PASS=$((PASS+1))
    else
      echo "✗ containerd image: vagrant-app:latest 不存在（Pod 將 ErrImageNeverPull）"; FAIL=$((FAIL+1))
    fi

    echo "=================================="
    echo "  結果: $PASS 通過 / $FAIL 失敗"
    echo "=================================="
    [ "$FAIL" -gt 0 ] && echo "提示: 執行 bash /vagrant/scripts/fix.sh restart 可嘗試修復"
    exit 0
  SHELL

  # 顯示完成訊息
  config.vm.provision "shell", name: "done", inline: <<-SHELL
    echo "=================================="
    echo "Kubernetes 環境安裝完成！"
    echo "=================================="
    echo "存取資訊："
    echo "  VM IP:     192.168.10.10"
    echo "  Frontend:  http://test6.test  (需設定 hosts)"
    echo "  K8s Dashboard:   https://192.168.10.10:9443/#/login"
    echo "  K8s API:   https://192.168.10.10:6443"
    echo "  Ollama:    http://localhost:11434  (VM 直接模式)"
    echo "=================================="
    echo "常用腳本（vagrant ssh 後執行）："
    echo "  bash /vagrant/scripts/check.sh status    # 整體狀態"
    echo "  bash /vagrant/scripts/fix.sh restart     # 重啟後一鍵恢復"
    echo "  bash /vagrant/scripts/app.sh logs        # App 日誌"
    echo "  bash /vagrant/scripts/test.sh chat       # Chat API 測試"
    echo "=================================="
    echo "K8s 快速查看："
    echo "  kubectl get nodes"
    echo "  kubectl get pods -A"
    echo "=================================="
  SHELL
end
