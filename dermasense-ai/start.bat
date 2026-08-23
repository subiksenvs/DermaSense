@echo off
setlocal enabledelayedexpansion

echo ===========================================
echo DermaSense Starter
echo ===========================================

echo Finding local IP address for mobile phone connection...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set LOCAL_IP=%%a
    set LOCAL_IP=!LOCAL_IP: =!
    goto :ipfound
)
:ipfound

if "%LOCAL_IP%"=="" (
    echo Could not determine local IP address. Defaulting to 10.0.2.2 for emulator.
    set LOCAL_IP=10.0.2.2
) else (
    echo Local IP address found: %LOCAL_IP%
)

echo.
echo ===========================================
echo Starting Skin-Scan AI Backend Server...
echo ===========================================
:: Start backend in a separate terminal window so it stays running
start "Skin-Scan Backend" cmd /k "cd skin-scan && C:\Users\Acer\AppData\Local\Python\pythoncore-3.14-64\python.exe -m uvicorn src.app.main:app --host 0.0.0.0 --port 8000 --reload"

echo.
echo Waiting 5 seconds for backend to initialize...
timeout /t 5 /nobreak >nul

echo.
echo ===========================================
echo Starting DermaSense Flutter App...
echo ===========================================
echo The app will connect to the backend at: http://%LOCAL_IP%:8000
cd frontend
flutter run --dart-define=API_URL=http://%LOCAL_IP%:8000

echo.
echo App closed. To stop the backend, close the other terminal window.
pause
