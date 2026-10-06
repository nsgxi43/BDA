#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
./scripts/setup.sh
./scripts/00-prepare.sh
./scripts/01-create-put.sh
./scripts/02-bulk-load.sh
./scripts/03-get-scan-count.sh
./scripts/04-delete-restore.sh
./scripts/05-query1.sh
./scripts/06-query2.sh
./scripts/07-query3.sh
./scripts/08-query4.sh
./scripts/09-java.sh
echo 'All Section 10 steps completed. Logs are in output/.'
