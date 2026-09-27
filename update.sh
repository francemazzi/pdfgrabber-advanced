#!/usr/bin/env bash

set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR" || exit 1

if ! command -v git >/dev/null 2>&1; then
  printf '[ERRORE/ERROR PG-UPDATE-001] Git non e installato. / Git is not installed.\n' >&2
  exit 1
fi

printf 'Aggiorno PDFGrabber... / Updating PDFGrabber...\n'
if ! git pull --ff-only; then
  printf '[ERRORE/ERROR PG-UPDATE-002] Aggiornamento interrotto; nessun avvio eseguito. / Update stopped; startup was not run.\n' >&2
  exit 1
fi

exec bash "$ROOT_DIR/start-web.sh" --docker
