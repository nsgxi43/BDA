#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"; load_query_vars
F="PrefixFilter('${UPSTREAM}#') OR PrefixFilter('${SECOND_SERVICE}#')"
source "$(dirname "$0")/query-common.sh"
query_run 08-query4 "Show calls where the upstream service is either ${UPSTREAM} OR ${SECOND_SERVICE}." "$F" "['meta:um','meta:dm','meta:traceid','meta:rpcid']"
