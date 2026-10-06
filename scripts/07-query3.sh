#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"; load_query_vars
F="ColumnPrefixFilter('interface') AND SingleColumnValueFilter('metrics','rt_ord', <,'binary:${MEDIAN_ENCODED}',true,true)"
source "$(dirname "$0")/query-common.sh"
query_run 07-query3 "Which records have an interface qualifier and response time below the sample median?" "$F" "['meta:interface']"
