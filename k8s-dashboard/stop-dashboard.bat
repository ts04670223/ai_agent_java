@echo off
chcp 65001 > nul
REM Stop Kubernetes Dashboard Proxy

echo =========================================
echo Stop Kubernetes Dashboard
echo =========================================
echo.

echo Stopping kubectl proxy process...

REM Kill all kubectl proxy processes
vagrant ssh -c "pkill -f 'kubectl proxy'" 2>nul

echo.
echo [OK] Dashboard proxy stopped
echo.
echo Note: You can also close the "Kubernetes Dashboard Proxy" terminal window directly
echo.
pause
