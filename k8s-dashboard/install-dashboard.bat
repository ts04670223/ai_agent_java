@echo off
chcp 65001 > nul
REM Kubernetes Dashboard Installation Script (Windows)

echo =========================================
echo Kubernetes Dashboard Installation
echo =========================================
echo.

REM Check if Vagrant is running
echo [1/3] Checking Vagrant VM status...
vagrant status | findstr "running" > nul
if errorlevel 1 (
    echo Error: Vagrant VM is not running
    echo Starting VM...
    vagrant up
    if errorlevel 1 (
        echo Failed to start VM!
        pause
        exit /b 1
    )
)
echo [OK] Vagrant VM is running
echo.

REM Check if Kubernetes is installed
echo [2/3] Checking Kubernetes status...
vagrant ssh -c "kubectl version --client" > nul 2>&1
if errorlevel 1 (
    echo Error: Kubernetes is not installed
    echo Please run Kubernetes installation script first
    pause
    exit /b 1
)
echo [OK] Kubernetes is installed
echo.

REM Execute installation script
echo [3/3] Installing Kubernetes Dashboard...
echo This may take a few minutes...
echo.

vagrant ssh -c "sudo bash /vagrant/k8s-dashboard/install-dashboard.sh"

if errorlevel 1 (
    echo.
    echo Installation failed!
    echo Please check the error messages above
    pause
    exit /b 1
)

echo.
echo =========================================
echo Installation Complete!
echo =========================================
echo.
echo Next steps:
echo   1. Run start-dashboard.bat to start Dashboard
echo   2. Use token from k8s-dashboard\dashboard-token.txt to login
echo.
echo 或手動啟動:
echo   vagrant ssh
echo   kubectl proxy --address='0.0.0.0' --accept-hosts='.*'
echo.
pause
