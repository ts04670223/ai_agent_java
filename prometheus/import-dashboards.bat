@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║     Grafana Dashboard 一鍵導入工具                    ║
echo ╚════════════════════════════════════════════════════════╝
echo.

set DASHBOARD_DIR=%~dp0dashboards
set GRAFANA_URL=http://localhost:30300

echo 📂 Dashboard 檔案位置: %DASHBOARD_DIR%
echo 🌐 Grafana 位址: %GRAFANA_URL%
echo.

REM 檢查 dashboards 目錄是否存在
if not exist "%DASHBOARD_DIR%" (
    echo ❌ 錯誤: 找不到 dashboards 目錄
    echo    請確認執行位置正確
    pause
    exit /b 1
)

echo ════════════════════════════════════════════════════════
echo  可用的 Dashboard 檔案:
echo ════════════════════════════════════════════════════════
echo.

set COUNT=0
for %%F in ("%DASHBOARD_DIR%\*.json") do (
    set /a COUNT+=1
    echo [!COUNT!] %%~nxF
)

if %COUNT%==0 (
    echo ❌ 沒有找到 JSON 檔案
    pause
    exit /b 1
)

echo.
echo ════════════════════════════════════════════════════════
echo.
echo 選擇導入方式:
echo.
echo [1] 開啟 Grafana Import 頁面 (推薦 - 手動選擇檔案)
echo [2] 使用 API 自動導入 (需要正確的帳號密碼)
echo [3] 取消
echo.
set /p CHOICE="請輸入選項 (1-3): "

if "%CHOICE%"=="1" goto :manual_import
if "%CHOICE%"=="2" goto :api_import
if "%CHOICE%"=="3" goto :end
echo 無效的選項
goto :end

:manual_import
echo.
echo ════════════════════════════════════════════════════════
echo  手動導入步驟
echo ════════════════════════════════════════════════════════
echo.
echo 正在開啟 Grafana Import 頁面...
start %GRAFANA_URL%/dashboard/import
timeout /t 2 /nobreak >nul
echo.
echo ✅ 瀏覽器已開啟
echo.
echo 📝 請依照以下步驟操作:
echo.
echo   1. 點擊 [Upload JSON file] 按鈕
echo.
echo   2. 選擇要導入的檔案 (位於):
echo      %DASHBOARD_DIR%
echo.
echo      推薦檔案:
echo      ├─ spring-boot-jvm-fixed.json  (JVM 監控)
echo      ├─ spring-boot-http.json       (HTTP 監控)
echo      └─ kubernetes-pods.json        (K8s Pod 監控)
echo.
echo   3. 在 "Options" 區域:
echo      └─ Select a Prometheus data source: 選擇 "Prometheus"
echo.
echo   4. 點擊 [Import] 按鈕
echo.
echo   5. 完成！ 如果看不到圖表:
echo      ├─ 檢查右上角時間範圍 (建議選 "Last 6 hours")
echo      ├─ 點擊面板標題 → Edit → 重新選擇 Data source
echo      └─ 確認 Prometheus 有數據: %GRAFANA_URL:30300=30090%/targets
echo.
echo ════════════════════════════════════════════════════════
echo.
choice /c YN /m "是否開啟 Dashboard 檔案所在資料夾"
if errorlevel 2 goto :end
explorer "%DASHBOARD_DIR%"
goto :end

:api_import
echo.
echo ════════════════════════════════════════════════════════
echo  使用 API 自動導入
echo ════════════════════════════════════════════════════════
echo.
set /p USERNAME="Grafana 使用者名稱 [admin]: " || set USERNAME=admin
set /p PASSWORD="Grafana 密碼 [NewAdminPassword123]: " || set PASSWORD=NewAdminPassword123
echo.
echo 正在導入 Dashboard...
echo.

set SUCCESS_COUNT=0
set FAIL_COUNT=0

for %%F in ("%DASHBOARD_DIR%\*.json") do (
    echo [導入中] %%~nxF
    
    vagrant ssh -c "curl -X POST -H 'Content-Type: application/json' -u %USERNAME%:%PASSWORD% -d @/vagrant/prometheus/dashboards/%%~nxF http://localhost:30300/api/dashboards/db" 2>nul | findstr /C:"success" >nul
    
    if !errorlevel! equ 0 (
        echo    ✅ 成功
        set /a SUCCESS_COUNT+=1
    ) else (
        echo    ❌ 失敗
        set /a FAIL_COUNT+=1
    )
    echo.
)

echo ════════════════════════════════════════════════════════
echo  導入結果
echo ════════════════════════════════════════════════════════
echo.
echo ✅ 成功: %SUCCESS_COUNT% 個
echo ❌ 失敗: %FAIL_COUNT% 個
echo.

if %FAIL_COUNT% gtr 0 (
    echo 💡 提示: 如果導入失敗，請:
    echo    1. 確認 Grafana 帳號密碼正確
    echo    2. 使用選項 [1] 手動導入
    echo.
)

choice /c YN /m "是否開啟 Grafana 查看導入的 Dashboard"
if errorlevel 2 goto :end
start %GRAFANA_URL%/dashboards
goto :end

:end
echo.
pause
endlocal
