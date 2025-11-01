@echo off
REM Start PDFGrabber Web UI
REM Opens at http://localhost:6066

echo 🌐 PDFGrabber Web UI Launcher
echo.

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Error: Docker is not running!
    echo    Open Docker Desktop and try again.
    pause
    exit /b 1
)

REM Check if images exist
docker images | findstr /C:"pdfgrabber" | findstr /C:"backend" >nul 2>&1
if %errorlevel% neq 0 (
    echo 📦 First time: building Docker images...
    echo    This will take 10-15 minutes...
    echo.
    docker-compose -f docker-compose.web.yml build
    echo.
    echo ✅ Images built successfully!
    echo.
)

REM Start services
echo 🚀 Starting PDFGrabber Web UI...
echo.
docker-compose -f docker-compose.web.yml up -d

echo.
echo ✅ PDFGrabber Web UI is running!
echo.
echo 🌐 Open your browser at:
echo    👉 http://localhost:6066
echo.
echo To stop the service, run:
echo    docker-compose -f docker-compose.web.yml down
echo.
pause

