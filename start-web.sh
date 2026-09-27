#!/usr/bin/env bash

set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
START_LOG="$ROOT_DIR/pdfgrabber-start.log"
URL="http://localhost:6066"
MODE=""
OPEN_BROWSER=1
COMPOSE=()
DOCKER_TIMEOUT="${PDFGRABBER_DOCKER_TIMEOUT:-120}"
HEALTH_TIMEOUT="${PDFGRABBER_HEALTH_TIMEOUT:-180}"

info() { printf '\n%s\n' "$1"; }
fail() {
  printf '\n[ERRORE/ERROR %s] %s\n' "$1" "$2" >&2
  exit 1
}
usage() {
  cat <<'EOF'
PDFGrabber Web

Uso / Usage:
  bash start-web.sh [--docker|--local] [--no-open]

  --docker   Avvia con Docker (predefinito) / Start with Docker (default)
  --local    Avvia con Python locale / Start with local Python
  --no-open  Non aprire il browser / Do not open the browser
  --help     Mostra questo aiuto / Show this help
EOF
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
wait_for_ready() {
  local elapsed=0
  printf 'Attendo il servizio / Waiting for service'
  while [ "$elapsed" -lt "$HEALTH_TIMEOUT" ]; do
    if ready; then printf ' OK\n'; return 0; fi
    printf '.'; sleep 2; elapsed=$((elapsed + 2))
  done
  printf '\n'; return 1
}
ensure_data() {
  local path
  for path in config.ini db.json; do
    [ ! -e "$ROOT_DIR/$path" ] || [ -f "$ROOT_DIR/$path" ] ||
      fail PG-START-005 "$path non e un file; nessun dato e stato modificato. / $path is not a file; no data was changed."
  done
  [ ! -e "$ROOT_DIR/files" ] || [ -d "$ROOT_DIR/files" ] ||
    fail PG-START-005 "files non e una cartella; nessun dato e stato modificato. / files is not a directory; no data was changed."
  [ -f "$ROOT_DIR/config.ini" ] || cp "$ROOT_DIR/config-default.ini" "$ROOT_DIR/config.ini"
  [ -f "$ROOT_DIR/db.json" ] || printf '{}\n' > "$ROOT_DIR/db.json"
  [ -d "$ROOT_DIR/files" ] || mkdir "$ROOT_DIR/files"
  if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "$ROOT_DIR/db.json" >/dev/null 2>&1 ||
      fail PG-START-005 "db.json non contiene JSON valido; correggilo o ripristina un backup. / db.json is invalid JSON; fix it or restore a backup."
  fi
}
start_docker_daemon() {
  info "Docker e installato ma non attivo. Provo ad avviarlo... / Docker is installed but not running. Trying to start it..."
  case "$(uname -s)" in
    Darwin) open -a Docker >/dev/null 2>&1 || true ;;
    Linux)
      systemctl --user start docker-desktop >/dev/null 2>&1 ||
        systemctl start docker >/dev/null 2>&1 || true
      ;;
  esac
  printf 'Attendo Docker / Waiting for Docker'
  local elapsed=0
  while [ "$elapsed" -lt "$DOCKER_TIMEOUT" ]; do
    if docker info >/dev/null 2>&1; then printf ' OK\n'; return 0; fi
    printf '.'; sleep 2; elapsed=$((elapsed + 2))
  done
  printf '\n'; return 1
}
detect_compose() {
  if docker compose version >/dev/null 2>&1; then COMPOSE=(docker compose)
  elif command -v docker-compose >/dev/null 2>&1; then COMPOSE=(docker-compose)
  else fail PG-START-003 "Docker Compose non e disponibile. Aggiorna Docker Desktop. / Docker Compose is unavailable. Update Docker Desktop."; fi
}
port_is_busy() {
  if command -v lsof >/dev/null 2>&1; then lsof -nP -iTCP:6066 -sTCP:LISTEN >/dev/null 2>&1
  elif command -v ss >/dev/null 2>&1; then ss -ltn 2>/dev/null | grep -qE '[:.]6066[[:space:]]'
  else return 1; fi
}
show_docker_diagnostics() {
  printf '\n--- Docker status ---\n'
  "${COMPOSE[@]}" -f "$ROOT_DIR/docker-compose.web.yml" ps 2>&1 || true
  printf '\n--- Last logs / Ultimi log ---\n'
  "${COMPOSE[@]}" -f "$ROOT_DIR/docker-compose.web.yml" logs --tail 80 2>&1 || true
}
run_docker() {
  command -v docker >/dev/null 2>&1 ||
    fail PG-START-001 "Docker non e installato: https://www.docker.com/products/docker-desktop/ / Docker is not installed."
  docker info >/dev/null 2>&1 || start_docker_daemon ||
    fail PG-START-002 "Docker non si e avviato entro 120 secondi. Apri Docker Desktop e riprova. / Docker did not start within 120 seconds."
  detect_compose
  ensure_data
  local frontend_id
  frontend_id="$("${COMPOSE[@]}" -f "$ROOT_DIR/docker-compose.web.yml" ps -q frontend 2>/dev/null || true)"
  if port_is_busy && [ -z "$frontend_id" ] && ! ready; then
    fail PG-START-004 "La porta 6066 e usata da un altro programma. / Port 6066 is used by another program."
  fi
  info "Avvio PDFGrabber con Docker... / Starting PDFGrabber with Docker..."
  if ! "${COMPOSE[@]}" -f "$ROOT_DIR/docker-compose.web.yml" up -d --build 2>&1 | tee "$START_LOG"; then
    show_docker_diagnostics
    fail PG-START-006 "Docker non ha avviato i servizi. Vedi $START_LOG / Docker failed to start the services. See $START_LOG"
  fi
  if ! wait_for_ready; then
    show_docker_diagnostics
    fail PG-START-007 "PDFGrabber non risponde su $URL. / PDFGrabber is not responding at $URL."
  fi
  open_browser
  info "PDFGrabber e pronto / PDFGrabber is ready: $URL"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --docker) MODE=docker ;;
    --local) MODE=local ;;
    --no-open) OPEN_BROWSER=0 ;;
    --help|-h) usage; exit 0 ;;
    *) usage; fail PG-START-000 "Opzione sconosciuta: $1 / Unknown option: $1" ;;
  esac
  shift
done

if [ -z "$MODE" ]; then
  printf 'PDFGrabber Web\n\n1) Docker (consigliato / recommended)\n2) Python locale / local Python\n\nScelta / Choice [1]: '
  read -r choice
  case "$choice" in 2) MODE=local ;; *) MODE=docker ;; esac
fi

cd "$ROOT_DIR" || fail PG-START-000 "Cartella progetto non accessibile. / Project directory is unavailable."
if [ "$MODE" = local ]; then
  args=(); [ "$OPEN_BROWSER" -eq 0 ] && args+=(--no-open)
  exec bash "$ROOT_DIR/start.sh" "${args[@]}"
fi
run_docker
