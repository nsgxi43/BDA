query_run() {
  local label="$1" question="$2" filter="$3" columns="$4"
  source "$(dirname "$0")/common.sh"
  source "$(dirname "$0")/logging.sh"
  start_log "$label"
  load_query_vars
  ensure_service
  echo "APPLICATION QUESTION: $question"
  echo "FILTER: $filter"
  echo "COMMAND: scan 'ms_callgraph', {FILTER => \"$filter\", COLUMNS => $columns, LIMIT => 5}"
  hbase_shell "$label" "scan 'ms_callgraph', {FILTER => \"$filter\", COLUMNS => $columns, LIMIT => 5}"
  echo "COMMAND: count 'ms_callgraph', {FILTER => \"$filter\"}"
  hbase_shell "$label" "count 'ms_callgraph', {FILTER => \"$filter\"}"
}
