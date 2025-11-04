@echo off
REM PDFGrabber Web - Start Script (Windows)
REM Avvia PDFGrabber Web UI senza Docker

setlocal enabledelayedexpansion

echo ========================================
echo  PDFGrabber Web - Avvio senza Docker
echo ========================================
echo.

REM Verifica Python
echo [INFO] Verifica installazione Python...
where python >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERRORE] Python non trovato!
    echo Installa Python 3.10 o superiore da https://www.python.org/downloads/
    echo Assicurati di selezionare "Add Python to PATH" durante l'installazione
    pause
    exit /b 1
)

REM Verifica versione Python
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo [OK] Python %PYTHON_VERSION% trovato
echo.

REM Crea virtual environment se non esiste
if not exist "venv\" (
    echo [INFO] Creazione ambiente virtuale...
    python -m venv venv
    if %ERRORLEVEL% NEQ 0 (
        echo [ERRORE] Impossibile creare l'ambiente virtuale
        pause
        exit /b 1
    )
    echo [OK] Ambiente virtuale creato
) else (
    echo [OK] Ambiente virtuale gia esistente
)
echo.

REM Attiva virtual environment
echo [INFO] Attivazione ambiente virtuale...
call venv\Scripts\activate.bat
if %ERRORLEVEL% NEQ 0 (
    echo [ERRORE] Impossibile attivare l'ambiente virtuale
    pause
    exit /b 1
)
echo [OK] Ambiente virtuale attivato
echo.

REM Installa/aggiorna dipendenze
echo [INFO] Installazione dipendenze...
echo        Questo potrebbe richiedere alcuni minuti alla prima esecuzione...
python -m pip install --upgrade pip >nul 2>&1
pip install -r backend\requirements.txt >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERRORE] Errore nell'installazione delle dipendenze
    echo Esegui manualmente: pip install -r backend\requirements.txt
    pause
    exit /b 1
)
echo [OK] Dipendenze installate
echo.

REM Crea directory files se non esiste
if not exist "files\" mkdir files
echo [OK] Directory files pronta
echo.

REM Avvia server integrato (backend + frontend)
echo [INFO] Avvio PDFGrabber Web Server (porta 6066)...
cd backend
start /B python -m uvicorn main:app --host 0.0.0.0 --port 6066 --log-level warning >../server.log 2>&1
cd ..
timeout /t 3 /nobreak >nul
echo [OK] Server avviato
echo.

REM Attendi che il server sia pronto
echo [INFO] Attesa avvio completo del server...
set ATTEMPTS=0
:check_server
curl -s http://localhost:6066/ >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Server pronto!
    goto server_ready
)
set /a ATTEMPTS+=1
if %ATTEMPTS% GEQ 30 (
    echo [ERRORE] Timeout: il server non risponde
    echo Controlla il file server.log per dettagli
    pause
    exit /b 1
)
timeout /t 1 /nobreak >nul
goto check_server

:server_ready
echo.

REM Apri il browser
echo [INFO] Apertura browser...
start http://localhost:6066
echo.

REM Informazioni finali
echo ========================================
echo  PDFGrabber Web e' in esecuzione!
echo ========================================
echo.
echo  Web UI:     http://localhost:6066
echo  API:        http://localhost:6066/api
echo.
echo  I file scaricati saranno in: files\
echo.
echo  Premi Ctrl+C o chiudi questa finestra per arrestare il server
echo.
echo ========================================
echo.

REM Mantieni la finestra aperta
pause >nul

