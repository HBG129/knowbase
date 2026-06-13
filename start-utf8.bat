@echo off
chcp 65001 >nul
title KnowBase
echo.
echo   鈺斺晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晽
echo   鈺?       KnowBase - AI 鐭ヨ瘑搴?         鈺?echo   鈺?       Desktop Edition               鈺?echo   鈺氣晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨暆
echo.
echo   [1/2] 鍚姩鍚庣鏈嶅姟...
cd /d "%~dp0backend"
start "KnowBase-Backend" /MIN cmd /c ".venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000 2>&1"
echo          鉁?鍚庣宸插惎鍔?(http://127.0.0.1:8000)

echo   [2/2] 鍚姩鍓嶇鐣岄潰...
cd /d "%~dp0frontend"
start "KnowBase-Frontend" /MIN cmd /c "npx next dev -p 3000 2>&1"
echo          鉁?鍓嶇宸插惎鍔?(http://localhost:3000)

echo.
echo   鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
echo   姝ｅ湪鎵撳紑娴忚鍣?..
timeout /t 4 /nobreak >nul
start http://localhost:3000
echo.
echo   馃帀 KnowBase 宸插氨缁紒
echo   鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
echo   馃摉 鍓嶇: http://localhost:3000
echo   馃敡 API:  http://localhost:8000/api/health
echo   馃搧 鏁版嵁: %~dp0backend\data\
echo   鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
echo.
echo   鎸変换鎰忛敭鍋滄鏈嶅姟...
pause >nul

echo   姝ｅ湪鍋滄鏈嶅姟...
taskkill /FI "WINDOWTITLE eq KnowBase-Backend*" /F >nul 2>&1
taskkill /FI "WINDOWTITLE eq KnowBase-Frontend*" /F >nul 2>&1
echo   宸插仠姝€傚啀瑙侊紒
timeout /t 2 /nobreak >nul
