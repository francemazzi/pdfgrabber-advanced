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

REM Create necessary files if they don't exist
echo 🔧 Checking required files...

REM Create db.json if it doesn't exist
if not exist db.json (
    echo    Creating db.json...
    echo {}> db.json
) else (
    REM Check if it's a directory and recreate as file
    if exist db.json\* (
        echo    Fixing db.json...
        rmdir /s /q db.json
        echo {}> db.json
    )
)

REM Create config.ini from default if it doesn't exist
if not exist config.ini (
    echo    Creating config.ini...
    copy config-default.ini config.ini >nul
) else (
    REM Check if it's a directory and recreate as file
    if exist config.ini\* (
        echo    Fixing config.ini...
        rmdir /s /q config.ini
        copy config-default.ini config.ini >nul
    )
)

REM Create files directory
if not exist files mkdir files

echo ✅ All files ready!
echo.

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

