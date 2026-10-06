#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/logging.sh"
start_log 04-delete-restore
need_data; ensure_service
ROWKEY="$(head -n 1 data/processed/mscallgraph.tsv | cut -f1)"
if docker compose exec -T hbase hbase shell -n -e "list_snapshots" 2>/dev/null | grep -q 'section10_before_delete'; then
  docker compose exec -T hbase hbase shell -n -e "delete_snapshot 'section10_before_delete'" >/dev/null
fi
echo "COMMAND: snapshot 'ms_callgraph', 'section10_before_delete'; count 'ms_callgraph'"
hbase_shell 04-delete-restore "snapshot 'ms_callgraph', 'section10_before_delete'; count 'ms_callgraph'"
echo "COMMAND: delete 'ms_callgraph', '$ROWKEY', 'metrics:rt_ms'; get row"
hbase_shell 04-delete-restore "delete 'ms_callgraph', '$ROWKEY', 'metrics:rt_ms'; get 'ms_callgraph', '$ROWKEY'"
echo "COMMAND: deleteall 'ms_callgraph', '$ROWKEY'; get row; count"
hbase_shell 04-delete-restore "deleteall 'ms_callgraph', '$ROWKEY'; get 'ms_callgraph', '$ROWKEY'; count 'ms_callgraph'"
echo "COMMAND: disable; restore_snapshot; enable; verify restored row and count"
hbase_shell 04-delete-restore "disable 'ms_callgraph'; restore_snapshot 'section10_before_delete'; enable 'ms_callgraph'; get 'ms_callgraph', '$ROWKEY'; count 'ms_callgraph'"
