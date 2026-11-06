@echo off
rem ============================================================
rem Local startup for this repo WITHOUT Docker.
rem   - Elasticsearch   : D:\dev-tools\es\elasticsearch-8.9.2
rem   - Embedding (TEI) : D:\dev-tools\local-stack\embedding_server.py
rem   - Backend         : uvicorn main:app  (port 8000)
rem   - Frontend        : vite dev          (port 5173)
rem MySQL is assumed to be the already-running local instance.
rem ============================================================
setlocal
cd /d "%~dp0"

echo [1/4] Elasticsearch :9200 ...
curl -s --noproxy "*" --max-time 3 http://127.0.0.1:9200 >nul 2>&1
if errorlevel 1 (
    start "shopkeeper-es" /min "D:\dev-tools\es\elasticsearch-8.9.2\bin\elasticsearch.bat"
) else (
    echo       already running
)

echo [2/4] Embedding service :8081 ...
curl -s --noproxy "*" --max-time 3 http://127.0.0.1:8081/health >nul 2>&1
if errorlevel 1 (
    start "shopkeeper-embedding" /min "D:\dev-tools\embedding-env\Scripts\python.exe" "D:\dev-tools\local-stack\embedding_server.py"
) else (
    echo       already running
)

echo [3/4] Waiting for ES / embedding ...
timeout /t 25 /nobreak >nul

echo [4/4] Backend :8000 and Frontend :5173 ...
curl -s --noproxy "*" --max-time 3 http://127.0.0.1:8000/docs >nul 2>&1
if errorlevel 1 (
    start "shopkeeper-backend" "cmd" /c ".venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000"
) else (
    echo       backend already running
)
curl -s --noproxy "*" --max-time 3 http://127.0.0.1:5173/ >nul 2>&1
if errorlevel 1 (
    start "shopkeeper-frontend" "cmd" /c "cd frontend && pnpm dev"
) else (
    echo       frontend already running
)

echo.
echo   Frontend : http://127.0.0.1:5173
echo   API docs : http://127.0.0.1:8000/docs
echo.
echo   To stop : close the 4 service windows, or run stop-local.bat once.
echo   MySQL 5.7 is a Windows service and is not managed here.
echo.
endlocal
