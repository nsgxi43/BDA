#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/logging.sh"
start_log 02-bulk-load
need_data
ensure_service
echo 'COMMAND: recreate ms_callgraph, create HFiles with ImportTsv, then load them.'
echo "CLEANED_ROWS=$(docker compose exec -T hbase python3 -c 'import json;print(json.load(open("/workspace/data/processed/manifest.json"))["retained_rows"])')"
hbase_shell 02-bulk-load "list"
if docker compose exec -T hbase hbase shell -n -e "list" | grep -qx 'ms_callgraph'; then
  hbase_shell 02-bulk-load "disable 'ms_callgraph'; drop 'ms_callgraph'"
fi
hbase_shell 02-bulk-load "create 'ms_callgraph', 'meta', 'metrics'"
echo 'COMMAND: hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.skip.bad.lines=false -Dimporttsv.bulk.output=/tmp/section10-hfiles -Dimporttsv.columns=HBASE_ROW_KEY,meta:traceid,meta:rpcid,meta:um,meta:dm,meta:rpctype,meta:interface,metrics:timestamp,metrics:rt_ord,metrics:rt_ms ms_callgraph /workspace/data/processed/mscallgraph.tsv'
docker compose exec -T hbase bash -lc 'rm -rf /tmp/section10-hfiles; hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.skip.bad.lines=false -Dimporttsv.bulk.output=/tmp/section10-hfiles -Dimporttsv.columns=HBASE_ROW_KEY,meta:traceid,meta:rpcid,meta:um,meta:dm,meta:rpctype,meta:interface,metrics:timestamp,metrics:rt_ord,metrics:rt_ms ms_callgraph /workspace/data/processed/mscallgraph.tsv' 2>&1 | tee -a output/02-bulk-load.log
echo 'COMMAND: hbase org.apache.hadoop.hbase.tool.LoadIncrementalHFiles /tmp/section10-hfiles ms_callgraph'
docker compose exec -T hbase hbase org.apache.hadoop.hbase.tool.LoadIncrementalHFiles /tmp/section10-hfiles ms_callgraph 2>&1 | tee -a output/02-bulk-load.log
hbase_shell 02-bulk-load "count 'ms_callgraph'"
