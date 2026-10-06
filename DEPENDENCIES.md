# Data provenance and dependency record

## Data source

- Owner: Alibaba clusterdata public repository, `cluster-trace-microservices-v2021`.
- Dataset: `MSCallGraph_0.tar.gz`, official object URL: `https://aliopentrace.oss-cn-beijing.aliyuncs.com/v2021MicroservicesTraces/MSCallGraph/MSCallGraph_0.tar.gz`.
- The official repository says the complete MSCallGraph directory is about 25 GiB and fetches 145 numbered chunks. This project fetches only chunk 0 and reports its HTTP Content-Length before downloading. If the source is unreachable, it accepts a user-provided CSV and records its relative path and hash.
- Schema is verified from the CSV header at runtime: `timestamp, traceid, rpcid, um, rpctype, interface, dm, rt` are required. The manifest preserves the actual header order and column names.
- Sampling: first up to 50,000 valid rows in source order. No random sampling. Processing stops once 50,000 valid unique keys have been retained.
- Cleaning: reject missing required fields; reject tab/newline field values that cannot be represented unambiguously in TSV; reject extra CSV fields; reject malformed integer timestamp/rt, negative timestamps, out-of-range signed 64-bit rt, and later duplicate composite keys. Preserve negative rt because Alibaba documents signed upstream/downstream RPC observations. Rejection totals include encountered rows before the 50,000 valid-row stop condition.
- Generated evidence in `data/processed/manifest.json`: source filename and SHA-256, cleaned TSV SHA-256, rows retained/rejected by reason, time range, uniqueness flag and thresholds. These values are created only from the real CSV.

## Runtime

| Component | Pin / selection |
|---|---|
| Apache HBase | 2.5.16 binary distribution, downloaded from Apache archive in the Docker build |
| Java | Eclipse Temurin OpenJDK 11, `11-jdk-jammy` multi-architecture image |
| Docker Compose | Compose V2 plugin supplied by Docker Desktop |
| Host scripting | macOS Bash, Git, Docker CLI, `curl`; data parser and Java compile/run execute in container |
| HBase mode | Standalone (`hbase.cluster.distributed=false`) with local persistent filesystem |

HBase’s Java client comes from the exact same HBase installation used by the local server, preventing client/server dependency drift. The base image is a versioned Temurin Java 11 tag; Docker resolves its architecture variant for Apple Silicon or Intel. The container image is built locally and is not committed.

## Execution record

The source and runtime availability vary by user machine. On a successful run, `output/00-dataset-profile.log` contains the manifest and `output/01-*` through `output/09-*` contain actual command output and exit status. A missing output log means that step has not been run. Do not infer results from a missing log.

## Authoring-machine validation

This project was prepared on macOS Apple Silicon (`arm64`) with Docker CLI present and Docker Compose 5.5.1. Shell syntax, Python syntax, Compose configuration, and the HBase XML were checked. A temporary development-only CSV fixture verified quoting, missing/malformed values, duplicate-key rejection and signed-int64 response-time ordering; it was stored outside the repository and is not report data. Docker Desktop could not start because `/Applications/Docker.app/Contents/MacOS/Docker` is missing, and DNS could not resolve `archive.apache.org`. The HBase image, official dataset, bulk load, shell filters, Java client, delete/restore and rerun behavior therefore have not been runtime-tested on this machine. No execution logs or screenshots are included as if they had run.
