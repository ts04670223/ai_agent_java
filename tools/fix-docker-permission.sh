#!/bin/bash
# 修復 Docker 權限問題

echo "========================================"
echo "  Docker Permission Fix"
echo "========================================"
echo ""

# 檢查 Docker 是否安裝
if ! command -v docker &> /dev/null; then
    echo "[ERROR] Docker is not installed"
    echo "Please install Docker first"
    exit 1
fi

# 檢查 Docker 是否運行
if ! sudo systemctl is-active --quiet docker; then
    echo "Starting Docker service..."
    sudo systemctl start docker
    sudo systemctl enable docker
    sleep 3
    echo "[OK] Docker started"
else
    echo "[OK] Docker is running"
fi

# 添加當前用戶到 docker 組
echo "Adding user '$USER' to docker group..."
sudo usermod -aG docker $USER

# 修改 socket 權限（立即生效）
echo "Setting socket permissions..."
sudo chmod 666 /var/run/docker.sock

# 驗證修復
echo ""
echo "Testing Docker access..."
if docker ps &> /dev/null; then
    echo "[OK] Docker access fixed!"
else
    echo "[WARNING] May need to logout/login for group changes to take effect"
fi

echo ""
echo "========================================"
echo "  Fix Complete!"
echo "========================================"
echo ""
echo "You can now run Docker commands without sudo:"
echo "  docker ps"
echo "  docker compose up -d --build"
echo ""
