#!/usr/bin/env bash

set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
URL="http://localhost:6066"
SETUP_LOG="$ROOT_DIR/pdfgrabber-setup.log"
SERVER_LOG="$ROOT_DIR/server.log"
OPEN_BROWSER=1
SERVER_PID=""

[ "${1:-}" = "--no-open" ] && OPEN_BROWSER=0

fail() {
  printf '\n[ERRORE/ERROR %s] %s\n' "$1" "$2" >&2
  exit 1
}
open_browser() {
  [ "$OPEN_BROWSER" -eq 0 ] && return
  if command -v open >/dev/null 2>&1; then open "$URL" >/dev/null 2>&1 &
  elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$URL" >/dev/null 2>&1 &
  else printf 'Apri manualmente / Open manually: %s\n' "$URL"; fi
}
ready() {
  command -v curl >/dev/null 2>&1 &&
    curl -fsS --max-time 3 "$URL/api/services" 2>/dev/null | grep -q '"services"'
}
cleanup() {
  trap - EXIT INT TERM
  if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    printf '\nArresto server / Stopping server...\n'
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}
ensure_data() {
  local path
  for path in config.ini db.json; do
    [ ! -e "$ROOT_DIR/$path" ] || [ -f "$ROOT_DIR/$path" ] ||
      fail PG-START-005 "$path non e un file; nessun dato e stato modificato. / $path is not a file; no data was changed."
  done
  [ ! -e "$ROOT_DIR/files" ] || [ -d "$ROOT_DIR/files" ] ||
    fail PG-START-005 "files non e una cartella. / files is not a directory."
  [ -f "$ROOT_DIR/config.ini" ] || cp "$ROOT_DIR/config-default.ini" "$ROOT_DIR/config.ini"
  [ -f "$ROOT_DIR/db.json" ] || printf '{}\n' > "$ROOT_DIR/db.json"
  [ -d "$ROOT_DIR/files" ] || mkdir "$ROOT_DIR/files"
}

cd "$ROOT_DIR" || fail PG-START-000 "Cartella progetto non accessibile. / Project directory is unavailable."
PYTHON_BIN="$(command -v python3 || command -v python || true)"
[ -n "$PYTHON_BIN" ] || fail PG-START-101 "Python 3.10+ non e installato. / Python 3.10+ is not installed."
"$PYTHON_BIN" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)' ||
  fail PG-START-102 "Serve Python 3.10 o superiore. / Python 3.10 or newer is required."

ensure_data
if ready; then
  open_browser
  printf 'PDFGrabber e gia pronto / PDFGrabber is already ready: %s\n' "$URL"
  exit 0
fi
if command -v lsof >/dev/null 2>&1 && lsof -nP -iTCP:6066 -sTCP:LISTEN >/dev/null 2>&1; then
  fail PG-START-004 "La porta 6066 e usata da un altro programma. / Port 6066 is used by another program."
fi

printf 'Preparo Python / Preparing Python...\n'
if [ ! -x "$ROOT_DIR/venv/bin/python" ]; then
  "$PYTHON_BIN" -m venv "$ROOT_DIR/venv" >"$SETUP_LOG" 2>&1 || {
    tail -n 40 "$SETUP_LOG" >&2
    fail PG-START-103 "Creazione ambiente virtuale fallita. / Failed to create the virtual environment."
  }
fi
VENV_PYTHON="$ROOT_DIR/venv/bin/python"
if ! "$VENV_PYTHON" -m pip install -r "$ROOT_DIR/backend/requirements.txt" >"$SETUP_LOG" 2>&1; then
  tail -n 40 "$SETUP_LOG" >&2
  fail PG-START-104 "Installazione dipendenze fallita. / Dependency installation failed."
fi
if ! "$VENV_PYTHON" -m playwright install chromium >>"$SETUP_LOG" 2>&1; then
  tail -n 40 "$SETUP_LOG" >&2
  fail PG-START-105 "Installazione Chromium fallita. / Chromium installation failed."
fi

printf 'Avvio server / Starting server...\n'
"$VENV_PYTHON" -m uvicorn backend.main:app --host 0.0.0.0 --port 6066 --log-level info >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!
trap cleanup EXIT INT TERM

elapsed=0
while [ "$elapsed" -lt 60 ]; do
  if ready; then break; fi
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    tail -n 80 "$SERVER_LOG" >&2
    fail PG-START-106 "Il server si e arrestato. / The server stopped unexpectedly."
  fi
  sleep 1; elapsed=$((elapsed + 1))
done
if ! ready; then
  tail -n 80 "$SERVER_LOG" >&2
  fail PG-START-107 "Il server non risponde entro 60 secondi. / The server did not respond within 60 seconds."
fi

open_browser
printf '\nPDFGrabber e pronto / PDFGrabber is ready: %s\n' "$URL"
printf 'Premi Ctrl+C per arrestare / Press Ctrl+C to stop.\n\n'
wait "$SERVER_PID"
status=$?
SERVER_PID=""
exit "$status"
