@echo off
chcp 65001 >nul 2>&1
pushd "%~dp0.."

REM Kubernetes Environment Installation Script (Windows)
REM Usage: install.bat

echo =====================================
echo   Kubernetes Dev Environment Setup
echo   Vagrant + Docker + Kubernetes
echo =====================================
echo.

REM Create necessary directories
echo [2/5] Creating directories...
if not exist "scripts" mkdir scripts
if not exist "k8s-manifests" mkdir k8s-manifests
echo [OK] Directories created
echo.

REM Check script files
echo [3/5] Checking installation scripts...
if not exist "scripts\install-docker.sh" (
    echo [ERROR] Missing scripts\install-docker.sh
    pause
    exit /b 1
)

if not exist "scripts\install-k8s.sh" (
    echo [ERROR] Missing scripts\install-k8s.sh
    pause
    exit /b 1
)

if not exist "scripts\setup-k8s-cluster.sh" (
    echo [ERROR] Missing scripts\setup-k8s-cluster.sh
    pause
    exit /b 1
)

echo [OK] All scripts ready
echo.

REM Start Vagrant
echo [4/5] Starting Vagrant environment...
echo This will take 10-15 minutes, please wait...
echo.

vagrant up

if %errorlevel% equ 0 (
    echo.
    echo =====================================
    echo   Installation Complete!
    echo =====================================
    echo.
    echo Next steps:
    echo   1. Login to VM: vagrant ssh
    echo   2. Check cluster: kubectl get nodes
    echo   3. View Pods: kubectl get pods -A
    echo.
    echo For more info, see README-K8S.md
    echo =====================================
) else (
    echo.
    echo [ERROR] Installation failed, check error messages above
)

pause