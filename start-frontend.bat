@echo off
cd /d "%~dp0frontend"
npx next dev -p 3000 2> ..\data\frontend.log
