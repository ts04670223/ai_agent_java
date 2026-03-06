@echo off
echo.
echo Starting Frontend...
echo.

REM Change to frontend directory
cd /d "%~dp0..\frontend"

REM Check Node.js
node -v
if errorlevel 1 (
    echo.
    echo ERROR: Node.js not found
    echo Please add Node.js to your PATH
    pause
    exit /b 1
)

echo.
echo Installing dependencies if needed...
if not exist "node_modules" (
    call npm install
)

echo.
echo Starting dev server...
echo Frontend: http://localhost:3000
echo.

call npm run dev
