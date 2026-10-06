#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"; load_query_vars
F="SingleColumnValueFilter('meta','rpctype', =,'binary:${RPC_TYPE}',true,true) AND SingleColumnValueFilter('metrics','rt_ord', >,'binary:${P75_ENCODED}',true,true)"
source "$(dirname "$0")/query-common.sh"
query_run 06-query2 "Which ${RPC_TYPE} calls are slower than the measured 75th percentile?" "$F" "['meta:um','meta:dm','meta:rpctype','metrics:rt_ms']"
