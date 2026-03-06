@echo off
chcp 65001 > nul
REM Kubernetes Dashboard Start Script (Windows)
REM This script starts kubectl proxy and opens browser

echo =========================================
echo Kubernetes Dashboard Startup
echo =========================================
echo.

REM Check Vagrant status
echo [1/4] Checking Vagrant VM status...
vagrant status | findstr "running" > nul
if errorlevel 1 (
    echo Error: Vagrant VM is not running
    echo Please run: vagrant up
    pause
    exit /b 1
)
echo [OK] Vagrant VM is running
echo.

REM Check if Dashboard is installed
echo [2/4] Checking Dashboard installation...
vagrant ssh -c "kubectl get deployment kubernetes-dashboard -n kubernetes-dashboard" > nul 2>&1
if errorlevel 1 (
    echo Error: Dashboard is not installed
    echo Please run: install-dashboard.bat
    pause
    exit /b 1
)
echo [OK] Dashboard is installed
echo.

REM Start kubectl proxy (in background)
echo [3/4] Starting kubectl proxy...
echo Note: This will occupy a terminal window, do not close it
echo.

start "Kubernetes Dashboard Proxy" vagrant ssh -c "kubectl proxy --address='0.0.0.0' --accept-hosts='.*'"

REM Wait for proxy to start
echo Waiting for proxy to start (5 seconds)...
timeout /t 5 /nobreak > nul

REM Open browser
echo [4/4] Opening browser...
start http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

echo.
echo =========================================
echo Dashboard Started!
echo =========================================
echo.
echo Browser URL:
echo http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
echo.
echo Login Method: Select Token
echo Token Location: k8s-dashboard\dashboard-token.txt
echo.
echo View token:
echo   type k8s-dashboard\dashboard-token.txt
echo.
echo Note: Keep the kubectl proxy terminal window open
echo       Closing it will stop Dashboard access
echo.
pause
