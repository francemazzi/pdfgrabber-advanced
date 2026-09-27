@echo off
setlocal EnableExtensions
cd /d "%~dp0"

where git >nul 2>nul
if errorlevel 1 (
  echo [ERRORE/ERROR PG-UPDATE-001] Git non e installato. / Git is not installed.
  pause
  exit /b 1
)

echo Aggiorno PDFGrabber... / Updating PDFGrabber...
git pull --ff-only
if errorlevel 1 (
  echo [ERRORE/ERROR PG-UPDATE-002] Aggiornamento interrotto. / Update stopped.
  pause
  exit /b 1
)

call "%~dp0start-web.bat" --docker
exit /b %ERRORLEVEL%
