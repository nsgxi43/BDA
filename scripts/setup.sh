#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail() { printf 'SETUP BLOCKED: %s\n' "$1" >&2; exit 1; }
command -v git >/dev/null || fail 'Git is required. Install Xcode Command Line Tools: xcode-select --install, then rerun ./scripts/setup.sh.'
command -v docker >/dev/null || fail 'Docker CLI is missing. Install Docker Desktop from https://docs.docker.com/desktop/setup/install/mac-install/, open Docker.app, wait for Engine running, then rerun.'
docker compose version >/dev/null 2>&1 || fail 'Docker Compose v2 is missing. Update Docker Desktop, start it, then rerun.'
docker info >/dev/null 2>&1 || fail 'Docker CLI is present but its engine is stopped. Open Docker Desktop (open -a Docker), wait for Engine running, then rerun. If Docker Desktop cannot open or reports a missing executable, reinstall it from https://docs.docker.com/desktop/setup/install/mac-install/.'
curl -fsSI --max-time 10 https://archive.apache.org/ >/dev/null 2>&1 || fail 'Internet/DNS cannot reach archive.apache.org. Connect to the internet and rerun; no data have been downloaded.'
mkdir -p data/source data/processed output figures
printf 'Docker: '; docker version --format '{{.Server.Version}}'
printf 'Compose: '; docker compose version --short
printf 'Host architecture: '; uname -m
printf 'Building the pinned HBase 2.5.16 / OpenJDK 11 image (multi-architecture base image)...\n'
docker compose build hbase
printf 'Setup complete. Next: ./scripts/run-all.sh\n'
