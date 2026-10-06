#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"; source "$(dirname "$0")/logging.sh"
start_log 09-java
load_query_vars; ensure_service
echo "SHELL EQUIVALENT: PrefixFilter('${UPSTREAM}#') AND metrics:rt_ord > '${RT_THRESHOLD_ENCODED}', filterIfMissing=true"
echo 'COMMAND: hbase shell count using Query 1 filter'
Q1_FILTER="PrefixFilter('${UPSTREAM}#') AND SingleColumnValueFilter('metrics','rt_ord', >,'binary:${RT_THRESHOLD_ENCODED}',true,true)"
docker compose exec -T hbase hbase shell -n -e "count 'ms_callgraph', {FILTER => \"$Q1_FILTER\"}" 2>&1 | tee output/09-shell-count.tmp | tee -a output/09-java.log
SHELL_COUNT="$(docker compose exec -T hbase python3 -c "import re; s=open('/workspace/output/09-shell-count.tmp').read(); m=re.search(r'(?m)^\\s*(\\d+) row\\(s\\)',s) or re.search(r'COUNT\\s*=\\s*(\\d+)',s); print(m.group(1) if m else 'COUNT_PARSE_FAILED')")"
[[ "$SHELL_COUNT" != COUNT_PARSE_FAILED ]] || { echo 'Could not parse HBase shell count output; inspect output/09-java.log.' >&2; exit 1; }
rm -f output/09-shell-count.tmp
echo "SHELL_MATCHING_COUNT=$SHELL_COUNT"
echo 'COMMAND: javac -cp "$(hbase classpath)" -d /workspace/output/java /workspace/java/QueryOne.java'
docker compose exec -T hbase bash -lc 'mkdir -p /workspace/output/java && javac -cp "$(hbase classpath)" -d /workspace/output/java /workspace/java/QueryOne.java'
echo 'JAVA_COMPILE_STATUS=0'
echo "COMMAND: java QueryOne '$UPSTREAM' '$RT_THRESHOLD_ENCODED'"
docker compose exec -T hbase bash -lc "java -cp '/workspace/output/java:$(docker compose exec -T hbase hbase classpath | tr -d '\r')' QueryOne '$UPSTREAM' '$RT_THRESHOLD_ENCODED'" 2>&1 | tee -a output/09-java.log
JAVA_COUNT="$(grep '^JAVA_MATCHING_COUNT=' output/09-java.log | tail -n1 | cut -d= -f2)"
[[ "$JAVA_COUNT" == "$SHELL_COUNT" ]] || { echo "MISMATCH: shell=$SHELL_COUNT Java=$JAVA_COUNT" >&2; exit 1; }
echo "AGREEMENT: shell=$SHELL_COUNT Java=$JAVA_COUNT"
