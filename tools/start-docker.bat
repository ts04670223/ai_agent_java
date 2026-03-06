@echo off
REM Docker 快速啟動腳本

echo ========================================
echo  Spring Boot Docker Environment
echo ========================================
echo.

REM 檢測 docker-compose 命令
docker-compose version >nul 2>&1
if %errorlevel% equ 0 (
    set DOCKER_COMPOSE=docker-compose
) else (
    docker compose version >nul 2>&1
    if %errorlevel% equ 0 (
        set DOCKER_COMPOSE=docker compose
    ) else (
        echo [ERROR] Docker Compose not found
        echo Please install Docker Desktop or Docker Compose
        pause
        exit /b 1
    )
)

echo Using: %DOCKER_COMPOSE%
echo.

echo [1/3] Building Docker image...
%DOCKER_COMPOSE% build

if %errorlevel% neq 0 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)

echo.
echo [2/3] Starting services...
%DOCKER_COMPOSE% up -d

if %errorlevel% neq 0 (
    echo [ERROR] Failed to start services
    pause
    exit /b 1
)

echo.
echo [3/3] Checking status...
timeout /t 5 /nobreak >nul
%DOCKER_COMPOSE% ps

echo.
echo ========================================
echo  Services are running!
echo ========================================
echo.
echo Access your application:
echo   Application: http://localhost:8080
echo   API Docs: http://localhost:8080/swagger-ui.html
echo   MySQL: localhost:3306
echo   Redis: localhost:6379
echo.
echo View logs:
echo   %DOCKER_COMPOSE% logs -f app
echo.
echo Stop services:
echo   %DOCKER_COMPOSE% down
echo.
echo ========================================

pause
