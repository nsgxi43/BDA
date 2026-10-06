#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
ensure_service
record 00-acquire-data docker compose exec -T hbase python3 /workspace/scripts/acquire-data.py
record 00-dataset-profile docker compose exec -T hbase python3 /workspace/scripts/prepare-data.py
