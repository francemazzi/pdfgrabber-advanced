@echo off
REM Helper script to start PDFGrabber with Docker
REM For Windows

echo 🐳 PDFGrabber Docker Launcher
echo.

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
    docker-compose build
    echo.
    echo ✅ Image built successfully!
    echo.
)

REM Start PDFGrabber
echo 🚀 Starting PDFGrabber...
echo.
docker-compose run --rm pdfgrabber

echo.
echo 👋 PDFGrabber finished. Your PDFs are in the files/ folder
pause

