#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo 'Removing only this Compose project service, network and its project-scoped HBase volume.'
docker compose down -v
rm -rf data/processed
echo 'Reset complete. Source data remain in data/source/. Run ./scripts/run-all.sh to rebuild.'
