#!/bin/bash
# 測試網路連接並修復 DNS

echo "========================================"
echo "  Network & DNS Diagnostics"
echo "========================================"
echo ""

# 測試基本網路
echo "[1/5] Testing basic network..."
if ping -c 2 8.8.8.8 &> /dev/null; then
    echo "  [OK] Internet connection works"
else
    echo "  [ERROR] No internet connection"
fi

# 測試 DNS 解析
echo ""
echo "[2/5] Testing DNS resolution..."
if nslookup maven.aliyun.com &> /dev/null; then
    echo "  [OK] DNS resolution works"
else
    echo "  [WARNING] DNS resolution failed"
    echo "  Fixing DNS settings..."
    
    # 添加 Google DNS
    echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
    echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf > /dev/null
    
    echo "  [OK] DNS fixed"
fi

# 測試 Maven 倉庫連接
echo ""
echo "[3/5] Testing Maven repository..."
if curl -s --connect-timeout 5 https://maven.aliyun.com &> /dev/null; then
    echo "  [OK] Can connect to Maven Aliyun mirror"
else
    echo "  [WARNING] Cannot connect to Maven mirror"
fi

# 檢查 Docker 網路
echo ""
echo "[4/5] Checking Docker network..."
if docker network ls &> /dev/null; then
    echo "  [OK] Docker network accessible"
else
    echo "  [ERROR] Docker network issue"
fi

# 測試 Docker DNS
echo ""
echo "[5/5] Testing Docker DNS..."
if docker run --rm alpine nslookup maven.aliyun.com &> /dev/null; then
    echo "  [OK] Docker containers can resolve DNS"
else
    echo "  [WARNING] Docker DNS issue"
    echo ""
    echo "Configuring Docker daemon DNS..."
    
    sudo mkdir -p /etc/docker
    cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "dns": ["8.8.8.8", "8.8.4.4"],
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
}
EOF
    
    sudo systemctl restart docker
    sleep 3
    
    echo "  [OK] Docker DNS configured"
fi

echo ""
echo "========================================"
echo "  Network Check Complete"
echo "========================================"
echo ""
echo "You can now try:"
echo "  docker compose up -d --build"
echo ""
