#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose stop hbase
echo 'Stopped the Section 10 HBase service. The project volume is preserved.'
