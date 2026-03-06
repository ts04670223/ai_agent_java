@echo off
setlocal enabledelayedexpansion
echo.
echo ========================================
echo    Frontend Server Startup Tool
echo ========================================
echo.

REM Check if Node.js is installed
node -v 2>nul
if errorlevel 1 (
    echo [ERROR] Node.js not detected
    echo.
    echo Please install Node.js 18 or higher
    echo Download: https://nodejs.org/
    echo.
    echo Current PATH:
    echo %PATH%
    echo.
    pause
    exit /b 1
)

REM Display Node.js version
echo [CHECK] Node.js detected
node -v
npm -v
echo.

REM 切換到前端目錄
cd /d "%~dp0..\frontend"

REM Check if node_modules exists
if not exist "node_modules" (
    echo [INSTALL] First run, installing dependencies...
    echo This may take a few minutes, please wait...
    echo.
    call npm install
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [ERROR] npm install failed
        echo.
        echo Please try:
        echo 1. Run this script as Administrator
        echo 2. Or manually run: cd frontend ^&^& npm install
        echo.
        pause
        exit /b 1
    )
    echo.
    echo [SUCCESS] Dependencies installed
    echo.
)

REM Check if backend is running
echo [CHECK] Detecting backend service...
curl -s http://localhost:8080/actuator/health >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [WARNING] Backend service not running
    echo.
    echo Frontend needs backend API to work properly
    echo.
    echo Please start backend first:
    echo   Method 1: Run install.bat in another terminal
    echo   Method 2: Run tools\start-docker.bat
    echo.
    echo Continue to start frontend? (Y/N^)
    choice /C YN /N
    if errorlevel 2 exit /b 0
    echo.
) else (
    echo [SUCCESS] Backend service is running
    echo.
)

REM Start frontend dev server
echo ========================================
echo    Starting Frontend Dev Server...
echo ========================================
echo.
echo Frontend: http://localhost:3000
echo Backend API: http://localhost:8080
echo.
echo Press Ctrl+C to stop server
echo.
echo ========================================
echo.

REM Start Vite dev server
call npm run dev

REM If abnormal exit
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Frontend server failed to start
    echo.
    echo Common issues:
    echo 1. Port 3000 already in use
    echo    Solution: Use netstat -ano ^| findstr :3000 to find and kill process
    echo.
    echo 2. Dependencies not fully installed
    echo    Solution: Delete node_modules folder and run this script again
    echo.
    pause
    exit /b 1
)
