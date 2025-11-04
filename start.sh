#!/bin/bash
# PDFGrabber Web - Start Script (macOS/Linux)
# Avvia PDFGrabber Web UI senza Docker

set -e

echo "🚀 PDFGrabber Web - Avvio senza Docker"
echo "======================================"
echo ""

# Colori per output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verifica Python
echo "🔍 Verifica installazione Python..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 non trovato!${NC}"
    echo "Installa Python 3.10 o superiore da https://www.python.org/downloads/"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
REQUIRED_VERSION="3.10"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then 
    echo -e "${RED}❌ Python $PYTHON_VERSION trovato, ma è richiesto Python $REQUIRED_VERSION o superiore${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Python $PYTHON_VERSION trovato${NC}"
echo ""

# Crea virtual environment se non esiste
if [ ! -d "venv" ]; then
    echo "📦 Creazione ambiente virtuale..."
    python3 -m venv venv
    echo -e "${GREEN}✓ Ambiente virtuale creato${NC}"
else
    echo -e "${GREEN}✓ Ambiente virtuale già esistente${NC}"
fi
echo ""

# Attiva virtual environment
echo "🔧 Attivazione ambiente virtuale..."
source venv/bin/activate
echo -e "${GREEN}✓ Ambiente virtuale attivato${NC}"
echo ""

# Installa/aggiorna dipendenze
echo "📚 Installazione dipendenze..."
echo "   Questo potrebbe richiedere alcuni minuti alla prima esecuzione..."
pip install --upgrade pip > /dev/null 2>&1
pip install -r backend/requirements.txt > /dev/null 2>&1
echo -e "${GREEN}✓ Dipendenze installate${NC}"
echo ""

# Crea directory files se non esiste
mkdir -p files
echo -e "${GREEN}✓ Directory files pronta${NC}"
echo ""

# Funzione per pulire i processi in uscita
cleanup() {
    echo ""
    echo "🛑 Arresto server..."
    if [ ! -z "$SERVER_PID" ]; then
        kill $SERVER_PID 2>/dev/null || true
    fi
    echo -e "${GREEN}✓ Server arrestato${NC}"
    echo "Arrivederci! 👋"
    exit 0
}

trap cleanup EXIT INT TERM

# Avvia server integrato (backend + frontend)
echo "🚀 Avvio PDFGrabber Web Server (porta 6066)..."
cd backend
python3 -m uvicorn main:app --host 0.0.0.0 --port 6066 --log-level warning > ../server.log 2>&1 &
SERVER_PID=$!
cd ..
sleep 2

# Verifica che il server sia avviato
if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo -e "${RED}❌ Errore nell'avvio del server${NC}"
    echo "Controlla il file server.log per dettagli"
    exit 1
fi
echo -e "${GREEN}✓ Server avviato (PID: $SERVER_PID)${NC}"
echo ""

# Attendi che il server sia pronto
echo "⏳ Attesa avvio completo del server..."
for i in {1..30}; do
    if curl -s http://localhost:6066/ > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Server pronto!${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ Timeout: il server non risponde${NC}"
        exit 1
    fi
    sleep 1
done
echo ""

# Apri il browser
echo "🌐 Apertura browser..."
URL="http://localhost:6066"

if command -v xdg-open &> /dev/null; then
    xdg-open "$URL" > /dev/null 2>&1
elif command -v open &> /dev/null; then
    open "$URL"
elif command -v start &> /dev/null; then
    start "$URL"
else
    echo -e "${YELLOW}⚠️  Impossibile aprire il browser automaticamente${NC}"
    echo "Apri manualmente: $URL"
fi
echo ""

# Informazioni finali
echo "======================================"
echo -e "${GREEN}✅ PDFGrabber Web è in esecuzione!${NC}"
echo "======================================"
echo ""
echo "📍 Web UI:     $URL"
echo "🔌 API:        http://localhost:6066/api"
echo ""
echo "📁 I file scaricati saranno in: files/"
echo ""
echo -e "${YELLOW}Premi Ctrl+C per arrestare il server${NC}"
echo ""

# Mantieni lo script in esecuzione
while true; do
    # Verifica che il server sia ancora attivo
    if ! kill -0 $SERVER_PID 2>/dev/null; then
        echo -e "${RED}❌ Il server si è arrestato inaspettatamente${NC}"
        echo "Controlla il file server.log per dettagli"
        exit 1
    fi
    sleep 5
done

