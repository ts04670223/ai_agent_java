# Grafana WebSocket 快速修復（PowerShell 版本）
# 通過 Vagrant SSH 自動執行修復

Write-Host "========================================"  -ForegroundColor Cyan
Write-Host "Grafana WebSocket 快速修復工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 切換到項目目錄
Set-Location -Path "c:\JOHNY\test"

Write-Host "[1/3] 正在連接到 Vagrant VM..." -ForegroundColor Yellow
Write-Host ""

# 修復命令
$fixCommand = "KONG_ADMIN_URL='http://localhost:30003'; echo '刪除現有 grafana-route...'; curl -i -X DELETE `${KONG_ADMIN_URL}/routes/grafana-route; echo ''; echo '創建支持 WebSocket 的新路由...'; curl -i -X POST `${KONG_ADMIN_URL}/services/grafana/routes --data 'name=grafana-route' --data 'paths[]=/grafana' --data 'strip_path=false' --data 'protocols[]=http' --data 'protocols[]=https' --data 'protocols[]=ws' --data 'protocols[]=wss'; echo ''; echo '驗證配置:'; curl -s `${KONG_ADMIN_URL}/routes/grafana-route"

Write-Host "[2/3] 執行修復命令..." -ForegroundColor Yellow
Write-Host ""

# 執行命令
vagrant ssh -c $fixCommand

Write-Host ""
Write-Host "[3/3] 修復完成！" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "測試說明" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "請在瀏覽器中訪問：" -ForegroundColor White
Write-Host "  http://test6.test/grafana" -ForegroundColor Green
Write-Host ""
Write-Host "打開開發者工具（F12），檢查：" -ForegroundColor White
Write-Host "  ✓ 不應該再看到 WebSocket 錯誤" -ForegroundColor Gray
Write-Host "  ✓ Network 標籤應該顯示 WebSocket 連接成功" -ForegroundColor Gray
Write-Host ""
Write-Host "如果仍有問題，請查看詳細指南：" -ForegroundColor White
Write-Host "  kong\GRAFANA-WEBSOCKET-VM-FIX.md" -ForegroundColor Cyan
Write-Host ""

Read-Host "按 Enter 鍵退出"
