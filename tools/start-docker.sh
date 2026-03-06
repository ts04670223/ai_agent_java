#!/bin/bash

# Docker 快速啟動腳本

echo "========================================"
echo "  Spring Boot Docker Environment"
echo "========================================"
echo ""

# 檢測 docker-compose 命令
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
else
    echo "[ERROR] Docker Compose not found"
    echo "Please install Docker Compose:"
    echo "  https://docs.docker.com/compose/install/"
    exit 1
fi

# 檢查 Docker 權限
if ! docker ps &> /dev/null; then
    echo "[WARNING] Docker permission denied"
    echo "Fixing permissions..."
    echo ""
    
    # 嘗試修復權限
    sudo usermod -aG docker $USER
    
    echo "Permission fixed. Please run one of:"
    echo "  1. Logout and login again: exit, then vagrant ssh"
    echo "  2. Or use sudo: sudo ./start-docker.sh"
    echo "  3. Or run: newgrp docker, then ./start-docker.sh"
    exit 0
fi

echo "Using: $DOCKER_COMPOSE"
echo ""

echo "[1/3] Building Docker image..."
$DOCKER_COMPOSE build

if [ $? -ne 0 ]; then
    echo "[ERROR] Build failed"
    exit 1
fi

echo ""
echo "[2/3] Starting services..."
$DOCKER_COMPOSE up -d

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to start services"
    exit 1
fi

echo ""
echo "[3/3] Checking status..."
sleep 5
$DOCKER_COMPOSE ps

echo ""
echo "========================================"
echo "  Services are running!"
echo "========================================"
echo ""
echo "Access your application:"
echo "  Application: http://localhost:8080"
echo "  API Docs: http://localhost:8080/swagger-ui.html"
echo "  MySQL: localhost:3306"
echo "  Redis: localhost:6379"
echo ""
echo "View logs:"
echo "  $DOCKER_COMPOSE logs -f app"
echo ""
echo "Stop services:"
echo "  $DOCKER_COMPOSE down"
echo ""
echo "========================================"
