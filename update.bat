@echo off
REM ============================================================
REM PDFGrabber - Update Script (Windows)
REM ============================================================
REM This script:
REM 1. Updates code from Git
REM 2. Stops Docker containers
REM 3. Rebuilds and starts containers
REM 4. Opens browser at localhost:6066
REM ============================================================

setlocal enabledelayedexpansion

echo.
echo ============================================================
echo  PDFGrabber - Update and Restart
echo ============================================================
echo.

REM Check if Git is installed
where git >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Git is not installed or not in PATH
    echo Please install Git from: https://git-scm.com/download/win
    pause
    exit /b 1
)

REM Check if Docker is installed
where docker >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker is not installed or not in PATH
    echo Please install Docker Desktop from: https://www.docker.com/products/docker-desktop/
    pause
    exit /b 1
)

REM Step 1: Git Pull
echo [1/4] Updating code from Git...
echo ============================================================
git pull
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [WARNING] Git pull failed. Continue anyway? (Y/N)
    set /p continue=
    if /i "!continue!" NEQ "Y" (
        echo Update cancelled.
        pause
        exit /b 1
    )
)
echo.

REM Step 2: Stop Docker containers
echo [2/4] Stopping Docker containers...
echo ============================================================
docker-compose -f docker-compose.web.yml down
echo.

REM Step 3: Rebuild and start containers
echo [3/4] Rebuilding and starting containers...
echo ============================================================
echo This may take a few minutes...
docker-compose -f docker-compose.web.yml up -d --build
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Failed to start Docker containers
    echo Please check Docker Desktop is running
    pause
    exit /b 1
)
echo.

REM Wait for containers to be ready
echo [4/4] Waiting for services to be ready...
echo ============================================================
timeout /t 5 /nobreak >nul

REM Check if containers are running
docker ps --filter "name=pdfgrabber" --format "{{.Names}}" | findstr pdfgrabber >nul
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Containers may not be running properly
    echo Run 'docker ps' to check container status
) else (
    echo [SUCCESS] Containers are running!
)
echo.

echo ============================================================
echo  Update Complete!
echo ============================================================
echo.
echo Opening PDFGrabber Web Interface...
echo URL: http://localhost:6066
echo.
echo Press Ctrl+C in this window to view logs
echo Or close this window to run in background
echo.

REM Open browser
start http://localhost:6066

REM Show logs (optional)
echo ============================================================
echo Container Logs (Press Ctrl+C to exit):
echo ============================================================
docker-compose -f docker-compose.web.yml logs -f

