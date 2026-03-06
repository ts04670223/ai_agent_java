#!/bin/bash
# 環境安裝與設定腳本
# 用法：bash /vagrant/scripts/setup.sh <docker|k8s-install|k8s|kong|frontend|ollama|ollama-path|app-build|all>

set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
CMD="${1:-help}"

_docker() {
    echo "================================"
    echo "安裝 Docker..."
    echo "================================"
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | sudo gpg --dearmor --yes --batch \
          -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    sudo mkdir -p /etc/containerd
    containerd config default | sudo tee /etc/containerd/config.toml
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
    sudo systemctl enable containerd; sudo systemctl restart containerd
    sudo systemctl status containerd --no-pager

    sudo mkdir -p /etc/docker
    cat <<'EOF' | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": { "max-size": "100m" },
  "storage-driver": "overlay2"
}
EOF
    sudo systemctl enable docker
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo usermod -aG docker vagrant
    sudo docker --version
    echo -e "${GREEN}Docker 安裝完成！${NC}"
}

_k8s_install() {
    echo "================================"
    echo "安裝 Kubernetes 套件..."
    echo "================================"
    sudo swapoff -a
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

    cat <<'EOF' | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
    sudo modprobe overlay; sudo modprobe br_netfilter
    lsmod | grep br_netfilter; lsmod | grep overlay

    cat <<'EOF' | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
    sudo sysctl --system

    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl

    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key \
      | sudo gpg --dearmor --yes --batch \
          -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' \
      | sudo tee /etc/apt/sources.list.d/kubernetes.list

    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
    sudo systemctl enable kubelet

    kubectl version --client; kubeadm version
    echo -e "${GREEN}Kubernetes 套件安裝完成！${NC}"
}

_k8s() {
    echo "================================"
    echo "初始化 Kubernetes 叢集..."
    echo "================================"
    MASTER_IP="192.168.10.10"

    sudo systemctl enable containerd; sudo systemctl restart containerd
    sudo modprobe overlay; sudo modprobe br_netfilter; sudo sysctl --system

    echo "等待 Container Runtime 就緒..."
    for i in {1..10}; do
      sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock \
        version &>/dev/null && break || { echo "重試... ($i/10)"; sleep 3; }
    done

    # IP 變更時重置
    if [ -f /etc/kubernetes/admin.conf ] && ! grep -q "$MASTER_IP" /etc/kubernetes/admin.conf; then
      echo "偵測到 IP 變更，執行 kubeadm reset..."
      sudo kubeadm reset -f
      sudo rm -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
      sudo rm -rf /etc/cni/net.d /var/lib/cni/ /run/flannel/
      sudo systemctl restart containerd; sleep 5
    fi

    if [ ! -f /etc/kubernetes/admin.conf ]; then
      echo "初始化 K8s Master ($MASTER_IP)..."
      sudo kubeadm init \
        --apiserver-advertise-address=$MASTER_IP \
        --pod-network-cidr=10.244.0.0/16 \
        --node-name k8s-master
    else
      echo "K8s 已初始化，跳過 init"
    fi

    mkdir -p /home/vagrant/.kube
    sudo cp -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
    sudo chown vagrant:vagrant /home/vagrant/.kube/config
    export KUBECONFIG=/etc/kubernetes/admin.conf
    grep -q "KUBECONFIG" /home/vagrant/.bashrc \
      || echo "export KUBECONFIG=/home/vagrant/.kube/config" >> /home/vagrant/.bashrc

    echo "等待 API Server..."
    for i in {1..60}; do
      kubectl get nodes --request-timeout=2s &>/dev/null && { echo "API Server 就緒"; break; } || sleep 5
    done

    kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

    echo "安裝 Flannel..."
    sudo rm -rf /var/lib/cni/ /run/flannel/
    sudo mkdir -p /run/flannel/
    kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

    echo "等待 Flannel..."
    for i in {1..60}; do
      kubectl get pods -n kube-flannel | grep -q "Running" && { echo "Flannel 就緒"; break; } || sleep 5
    done

    echo -e "${GREEN}K8s 叢集初始化完成！${NC}"
    kubectl get nodes -o wide
}

_kong() {
    KONG_ADMIN="http://192.168.10.10:30003"
    echo "========================================"
    echo "配置 Kong Gateway 路由"
    echo "========================================"
    if ! curl -s -f "${KONG_ADMIN}" > /dev/null; then
      echo -e "${RED}✗ Kong Admin API 無法連線${NC}"
      echo "確認 Kong 是否運行: kubectl get pods | grep kong"
      exit 1
    fi
    echo -e "${GREEN}✓ Kong Admin API 正常${NC}"

    echo "清除現有配置..."
    for id in $(curl -s "${KONG_ADMIN}/routes" | grep -o '"id":"[^"]*"' | cut -d'"' -f4); do
      curl -s -X DELETE "${KONG_ADMIN}/routes/${id}" > /dev/null
    done
    for id in $(curl -s "${KONG_ADMIN}/services" | grep -o '"id":"[^"]*"' | cut -d'"' -f4); do
      curl -s -X DELETE "${KONG_ADMIN}/services/${id}" > /dev/null
    done

    echo "創建 app-service..."
    SVC=$(curl -s -X POST "${KONG_ADMIN}/services" \
      -H "Content-Type: application/json" \
      -d '{"name":"app-service","url":"http://app:8080","connect_timeout":60000,"read_timeout":360000,"write_timeout":360000}')
    SVC_ID=$(echo "$SVC" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    [ -n "$SVC_ID" ] && echo -e "${GREEN}✓ Service: $SVC_ID${NC}" || { echo -e "${RED}✗ Service 創建失敗${NC}"; echo "$SVC"; exit 1; }

    echo "創建 API 路由 /api..."
    RT=$(curl -s -X POST "${KONG_ADMIN}/services/app-service/routes" \
      -H "Content-Type: application/json" \
      -d '{"name":"api-route","paths":["/api"],"strip_path":false,"preserve_host":false}')
    RT_ID=$(echo "$RT" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    [ -n "$RT_ID" ] && echo -e "${GREEN}✓ Route: $RT_ID${NC}" || { echo -e "${RED}✗ Route 創建失敗${NC}"; echo "$RT"; exit 1; }

    echo "========================================"
    echo "Kong 路由配置完成"
    curl -s "${KONG_ADMIN}/routes" | grep -o '"name":"[^"]*"'
}

_frontend() {
    echo "================================"
    echo "設定前端環境..."
    echo "================================"
    CURRENT_NODE_VER=$(node -v 2>/dev/null || echo "none")
    if [[ "$CURRENT_NODE_VER" != v24* ]]; then
      echo "安裝 Node.js v24..."
      sudo apt-get remove -y nodejs npm || true
      sudo apt-get autoremove -y || true
      curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
      sudo apt-get install -y nodejs
    else
      echo "Node.js 已安裝: $CURRENT_NODE_VER"
    fi

    sudo npm install -g vite

    cd /vagrant/frontend
    if [ -d "node_modules" ] && [ ! -d "node_modules/vite" ]; then
      echo "node_modules 不完整，清理重裝..."
      rm -rf node_modules
    fi
    sudo -u vagrant npm install --no-bin-links

    echo "安裝並設定 Nginx..."
    sudo apt-get install -y nginx
    sudo cp /vagrant/scripts/nginx/nginx-test6.conf /etc/nginx/sites-available/test6.test
    sudo ln -sf /etc/nginx/sites-available/test6.test /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo nginx -t; sudo systemctl restart nginx

    echo "設定前端 Systemd 服務..."
    cat <<'EOF' | sudo tee /etc/systemd/system/frontend.service
[Unit]
Description=Frontend React App
After=network.target

[Service]
Type=simple
User=vagrant
WorkingDirectory=/vagrant/frontend
ExecStart=/usr/bin/npm run dev -- --host
Restart=always
RestartSec=10
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=development

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable frontend.service
    sudo systemctl restart frontend.service

    echo -e "${GREEN}前端設定完成！URL: http://test6.test${NC}"
}

_ollama() {
    echo "================================================="
    echo " Ollama VM 直接安裝                             "
    echo "================================================="
    if which ollama &>/dev/null; then
      echo "✓ Ollama 已安裝: $(ollama --version)"
    else
      echo "安裝 Ollama..."
      if wget -qO /tmp/_ollama_install.sh https://ollama.com/install.sh 2>/dev/null; then
        sudo sh /tmp/_ollama_install.sh
      else
        curl -fsSL https://ollama.com/install.sh | sh
      fi
      echo "✓ Ollama 安裝完成"
    fi

    sudo systemctl stop ollama-portforward 2>/dev/null || true
    sudo systemctl disable ollama-portforward 2>/dev/null || true

    id ollama &>/dev/null || sudo useradd -r -s /bin/false -m -d /usr/share/ollama ollama

    cat <<'EOF' | sudo tee /etc/systemd/system/ollama.service
[Unit]
Description=Ollama - Local LLM Service (VM Direct Mode)
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_NUM_PARALLEL=1"
Environment="OLLAMA_MAX_LOADED_MODELS=1"
Environment="OLLAMA_NUM_THREAD=4"

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable ollama
    sudo systemctl start ollama

    echo "等待 Ollama 就緒..."
    for i in {1..30}; do
      curl -s http://localhost:11434/api/tags &>/dev/null && { echo "✓ Ollama 就緒"; break; }
      printf "."; sleep 1
    done

    ollama list 2>/dev/null | grep -q "qwen2.5:0.5b" \
      && echo "✓ 模型 qwen2.5:0.5b 已存在" \
      || ollama pull qwen2.5:0.5b

    kubectl scale deployment ollama --replicas=0 2>/dev/null \
      && echo "✓ K8s Ollama Pod 縮減為 0" || true

    echo "================================================="
    echo "Ollama 安裝完成！"
    echo "  查看狀態: sudo systemctl status ollama"
    echo "  查看日誌: sudo journalctl -u ollama -f"
    echo "================================================="
}

_ollama_path() {
    echo "=== 確認 Ollama 模型路徑 ==="
    VAGRANT_MODELS="/home/vagrant/.ollama/models"
    OLLAMA_MODELS="/usr/share/ollama/.ollama/models"

    if [ -d "$VAGRANT_MODELS" ] && ls "$VAGRANT_MODELS/blobs/" 2>/dev/null | head -1 > /dev/null; then
      MODEL_SIZE=$(du -sh "$VAGRANT_MODELS" 2>/dev/null | cut -f1)
      echo "✓ 模型位於 vagrant 路徑: $MODEL_SIZE → 複製到 ollama 服務路徑"
      sudo mkdir -p "$OLLAMA_MODELS"
      sudo cp -r "$VAGRANT_MODELS"/* "$OLLAMA_MODELS/"
      sudo chown -R ollama:ollama /usr/share/ollama/.ollama/
      echo "✓ 複製完成: $OLLAMA_MODELS"
    elif [ -d "$OLLAMA_MODELS" ] && ls "$OLLAMA_MODELS/blobs/" 2>/dev/null | head -1 > /dev/null; then
      echo "✓ 模型已在正確路徑: $(du -sh "$OLLAMA_MODELS" | cut -f1)"
    else
      echo "⚠ 兩個路徑都沒有模型，重新拉取..."
      sudo -u ollama OLLAMA_MODELS="$OLLAMA_MODELS" ollama pull qwen2.5:0.5b 2>/dev/null \
        || ollama pull qwen2.5:0.5b
    fi

    sudo systemctl daemon-reload
    sudo systemctl restart ollama
    sleep 5
    sudo systemctl status ollama --no-pager | grep Active

    echo "=== 驗證模型 ==="
    for i in {1..15}; do
      MODELS=$(curl -s http://localhost:11434/api/tags 2>/dev/null)
      if echo "$MODELS" | grep -q "qwen2.5"; then
        echo -e "${GREEN}✓ 模型可用${NC}"
        ollama list; break
      fi
      [ $i -eq 15 ] && echo -e "${RED}✗ 模型驗證失敗${NC}" || sleep 2
    done
}

_app_build() {
    echo "=== 建立 App JAR（/tmp 暫存目錄，繞過 VirtualBox 共享資料夾限制）==="
    sudo systemctl stop spring-boot-app 2>/dev/null || true
    pkill -f 'spring-boot-demo' 2>/dev/null || true
    sleep 2

    rm -rf /tmp/appbuild
    mkdir /tmp/appbuild
    cp -r /vagrant/src /tmp/appbuild/
    cp /vagrant/pom.xml /tmp/appbuild/
    cd /tmp/appbuild
    mvn package -DskipTests -q
    cp target/spring-boot-demo-*.jar /vagrant/target/spring-boot-demo-0.0.1-SNAPSHOT.jar
    echo "BUILD_OK at $(date)"
    sudo systemctl start spring-boot-app && echo "SERVICE_STARTED"
}

case "$CMD" in
  docker)      _docker ;;
  k8s-install) _k8s_install ;;
  k8s)         _k8s ;;
  kong)        _kong ;;
  frontend)    _frontend ;;
  ollama)      _ollama ;;
  ollama-path) _ollama_path ;;
  app-build)   _app_build ;;
  all)
    _docker
    _k8s_install
    _k8s
    _kong
    _frontend
    _ollama
    ;;
  *)
    echo "環境安裝與設定腳本"
    echo ""
    echo "用法：bash /vagrant/scripts/setup.sh <指令>"
    echo ""
    echo "指令："
    echo "  docker       安裝 Docker Engine（含 containerd）"
    echo "  k8s-install  安裝 Kubernetes 套件（kubelet / kubeadm / kubectl）"
    echo "  k8s          初始化 K8s 叢集 + 安裝 Flannel"
    echo "  kong         設定 Kong Gateway 路由（/api → app:8080）"
    echo "  frontend     安裝 Node.js + Nginx + 前端 Systemd 服務"
    echo "  ollama       安裝 Ollama VM 直接模式 + 拉取 qwen2.5:0.5b"
    echo "  ollama-path  修正 Ollama 模型路徑（vagrant → ollama 用戶）"
    echo "  app-build    在 /tmp 重新編譯 JAR（繞過 VirtualBox 共享資料夾限制）"
    echo "  all          全套安裝（docker → k8s-install → k8s → kong → frontend → ollama）"
    ;;
esac
