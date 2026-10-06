#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p output data/source data/processed
record() {
  local name="$1"; shift
  local log="$ROOT/output/${name}.log"
  : > "$log"
  {
    printf '=== %s ===\n' "$name"
    printf 'COMMAND:'; printf ' %q' "$@"; printf '\n'
    set +e
    "$@" 2>&1
    local status=$?
    set -e
    printf 'EXIT_STATUS=%s\n' "$status"
    exit "$status"
  } | tee "$log"
}
hbase_shell() {
  local label="$1"; shift
  printf 'HBASE SHELL COMMAND: %s\n' "$*"
  docker compose exec -T hbase hbase shell -n -e "$*" 2>&1 | tee -a "output/${label}.log"
}
need_data() {
  [[ -s data/processed/mscallgraph.tsv && -s data/processed/query.env ]] || { echo 'Prepared data missing. Run ./scripts/00-prepare.sh.' >&2; exit 1; }
}
ensure_service() {
  docker compose up -d hbase
  local i
  for i in $(seq 1 60); do
    if [[ "$(docker compose ps --status running -q hbase | wc -l | tr -d ' ')" -gt 0 ]] && docker compose exec -T hbase hbase shell -n -e 'status' >/dev/null 2>&1; then
      echo 'HBase shell readiness check: READY'; return 0
    fi
    sleep 3
  done
  docker compose logs --tail=100 hbase >&2
  echo 'HBase did not become ready within 180 seconds.' >&2; return 1
}
load_query_vars() {
  need_data
  source data/processed/query.env
}
