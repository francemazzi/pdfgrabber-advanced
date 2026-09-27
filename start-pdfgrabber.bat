@echo off
REM Helper script to start PDFGrabber with Docker
REM For Windows

echo 🐳 PDFGrabber Docker Launcher
echo.

docker compose version >nul 2>&1
if not errorlevel 1 (
    set "COMPOSE=docker compose"
) else (
    where docker-compose >nul 2>&1
    if errorlevel 1 (
        echo Error: Docker Compose is not available. Update Docker Desktop.
        pause
        exit /b 1
    )
    set "COMPOSE=docker-compose"
)

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Error: Docker is not running!
    echo    Open Docker Desktop and try again.
    pause
    exit /b 1
)

REM Check if image exists
docker images | findstr /C:"pdfgrabber-advanced" >nul 2>&1
if %errorlevel% neq 0 (
    echo 📦 First time: building Docker image...
    echo    This will take 5-10 minutes...
    echo.
    %COMPOSE% build
    if errorlevel 1 exit /b 1
    echo.
    echo ✅ Image built successfully!
    echo.
)

REM Start PDFGrabber
echo 🚀 Starting PDFGrabber...
echo.
%COMPOSE% run --rm pdfgrabber
if errorlevel 1 exit /b 1

echo.
echo 👋 PDFGrabber finished. Your PDFs are in the files/ folder
pause
