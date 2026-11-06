@echo off
rem ============================================================
rem Stop the local services started by run-local.bat.
rem Only kills processes LISTENING on 9200 / 8081 / 8000 / 5173.
rem MySQL (port 3306) is a pre-existing Windows service and is NOT touched.
rem ============================================================
echo Stopping local services ...
powershell -NoProfile -Command "$ports=9200,8081,8000,5173; foreach($p in $ports){ $conns=Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue; foreach($c in $conns){ $proc=Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue; if($proc){ Write-Host ('  port ' + $p + ' -> stop ' + $proc.ProcessName + ' pid ' + $proc.Id); Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue } } }"
echo.
echo Done. MySQL 5.7 is untouched.
echo Data on disk is kept: D:\dev-tools\es\data, D:\dev-tools\qdrant-storage
pause
