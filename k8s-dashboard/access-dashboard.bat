@echo off
chcp 65001 > nul
REM Kubernetes Dashboard Access Guide

echo =========================================
echo Kubernetes Dashboard Access Guide
echo =========================================
echo.

echo [Access URL]
echo http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
echo.

echo [Login Method]
echo 1. Select "Token" login method
echo 2. Copy the following token:
echo.

if exist dashboard-token.txt (
    type dashboard-token.txt
    echo.
) else (
    echo Token file does not exist!
    echo Please run install-dashboard.bat to install Dashboard first
    echo.
)

echo [Quick Start]
echo Run: start-dashboard.bat
echo.

echo [Manual Start]
echo 1. vagrant ssh
echo 2. kubectl proxy --address='0.0.0.0' --accept-hosts='.*'
echo 3. Open the above URL in browser
echo.

echo [Stop Service]
echo Run: stop-dashboard.bat
echo.

echo [Check Status]
echo vagrant ssh -c "kubectl get pods -n kubernetes-dashboard"
echo.

pause
