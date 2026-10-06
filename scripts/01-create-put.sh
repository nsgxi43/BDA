#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/logging.sh"
start_log 01-create-put
ensure_service
echo "COMMANDS: create 'section10_demo', 'meta', 'metrics'; describe; put; scan"
if docker compose exec -T hbase hbase shell -n -e "list" | grep -qx 'section10_demo'; then
  hbase_shell 01-create-put "disable 'section10_demo'; drop 'section10_demo'"
fi
hbase_shell 01-create-put "create 'section10_demo', 'meta', 'metrics'; describe 'section10_demo'; put 'section10_demo', 'demo#0000000000001#trace-demo#0.1', 'meta:traceid', 'trace-demo'; put 'section10_demo', 'demo#0000000000001#trace-demo#0.1', 'meta:um', 'demo'; put 'section10_demo', 'demo#0000000000001#trace-demo#0.1', 'metrics:rt_ms', '12'; scan 'section10_demo', {LIMIT => 5}"
