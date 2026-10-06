#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"; load_query_vars
F="PrefixFilter('${UPSTREAM}#') AND SingleColumnValueFilter('metrics','rt_ord', >,'binary:${RT_THRESHOLD_ENCODED}',true,true)"
source "$(dirname "$0")/query-common.sh"
query_run 05-query1 "Which calls from upstream service ${UPSTREAM} exceed the measured 95th-percentile response-time threshold (${RT_THRESHOLD} ms)?" "$F" "['meta:um','meta:dm','meta:rpctype','metrics:rt_ms']"
