@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "PS_ARGS="
:parse
if "%~1"=="" goto run
if /I "%~1"=="--docker" (
  set "PS_ARGS=!PS_ARGS! -Docker"
) else if /I "%~1"=="--local" (
  set "PS_ARGS=!PS_ARGS! -Local"
) else if /I "%~1"=="--no-open" (
  set "PS_ARGS=!PS_ARGS! -NoOpen"
) else if /I "%~1"=="--help" (
  set "PS_ARGS=!PS_ARGS! -Help"
) else if /I "%~1"=="-h" (
  set "PS_ARGS=!PS_ARGS! -Help"
) else (
  echo [ERRORE/ERROR PG-START-000] Opzione sconosciuta / Unknown option: %~1
  pause
  exit /b 2
)
shift
goto parse

:run
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-web.ps1" %PS_ARGS%
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
  echo.
  echo Avvio non completato / Startup did not complete.
  pause
)
exit /b %EXIT_CODE%
