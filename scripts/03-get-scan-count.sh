#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/logging.sh"
start_log 03-get-scan-count
need_data; ensure_service
ROWKEY="$(head -n 1 data/processed/mscallgraph.tsv | cut -f1)"
echo "COMMAND: get 'ms_callgraph', '$ROWKEY'"
hbase_shell 03-get-scan-count "get 'ms_callgraph', '$ROWKEY'"
echo "COMMAND: scan 'ms_callgraph', {LIMIT => 5}"
hbase_shell 03-get-scan-count "scan 'ms_callgraph', {LIMIT => 5}"
echo "COMMAND: count 'ms_callgraph'"
hbase_shell 03-get-scan-count "count 'ms_callgraph'"
