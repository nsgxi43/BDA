#!/usr/bin/env bash
set -euo pipefail
mkdir -p /var/lib/hbase /var/lib/hbase/zookeeper
exec hbase master start
