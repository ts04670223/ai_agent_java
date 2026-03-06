# -*- mode: ruby -*-
# vi: set ft=ruby :

# Kubernetes Development Environment on Vagrant with Docker
Vagrant.configure("2") do |config|
  # 使用 Ubuntu 20.04 LTS (Kubernetes 相容性較好)
  config.vm.box = "ubuntu/focal64"
  
  # 配置虛擬機名稱和資源
  config.vm.provider "virtualbox" do |vb|
    vb.name = "k8s-dev-environment"
    vb.memory = "8192"  # K8s 需要至少 2GB，建議 4GB
    vb.cpus = 4
  end
  
  # 配置主機名稱
  config.vm.hostname = "k8s-master"
  
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
  config.vm.provision "shell", name: "setup-frontend",
    inline: "bash /vagrant/scripts/setup.sh frontend"
  config.vm.provision "shell", name: "install-ollama",
    inline: "bash /vagrant/scripts/setup.sh ollama"

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
ExecStart=/usr/bin/kubectl port-forward svc/redis 6379:6379 --address=127.0.0.1
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable redis-portforward.service
    systemctl restart redis-portforward.service
    echo "Redis port-forward service started (localhost:6379 -> K8s redis:6379)"
  SHELL

  # 配置 Kong 路由
  config.vm.provision "shell", name: "setup-kong", inline: <<-SHELL
    echo "等待 Kong 完全啟動..."
    sleep 30
    echo "配置 Kong 路由..."
    bash /vagrant/scripts/setup.sh kong
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
    
    # 停止舊的進程
    pkill -f "kubectl port-forward" || true
    
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
    echo "=== 編譯 Spring Boot JAR ==="
    bash /vagrant/scripts/setup.sh app-build
    echo "=== 建立 Docker image ==="
    cd /vagrant && docker build -t vagrant-app:latest -f Dockerfile.bak . 2>&1 | tail -3
    echo "=== 匯入 image 到 containerd (K8s) ==="
    docker save vagrant-app:latest > /tmp/vagrant-app.tar
    sudo ctr -n k8s.io images import /tmp/vagrant-app.tar
    rm -f /tmp/vagrant-app.tar
    echo "=== 部署 app 到 K8s ==="
    kubectl apply -f /vagrant/app-deployment.yaml
    kubectl apply -f /vagrant/app-service.yaml
    echo "Spring Boot app 已部署到 K8s (Ollama -> 192.168.10.10:11434)"
  SHELL

  # 顯示完成訊息
  config.vm.provision "shell", name: "done", inline: <<-SHELL
    echo "=================================="
    echo "Kubernetes 環境安裝完成！"
    echo "=================================="
    echo "存取資訊："
    echo "  VM IP:     192.168.10.10"
    echo "  Frontend:  http://test6.test  (需設定 hosts)"
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
