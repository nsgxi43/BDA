# Section 10 — Diya Bhat (MSCallGraph)

This repository prepares the individual Section 10 contribution in the assignment PDF. It runs Apache HBase 2.5.16 in standalone mode inside Docker with OpenJDK 11. The real Alibaba call graph input is one source chunk at most; processing retains no more than 50,000 valid records. HBase, Java compilation, data processing, and saved logs run in the container. The Mac needs Git, Docker Desktop, Docker Compose v2, and network access for the first image and dataset downloads.

## Clone and run

```bash
git clone <repository-url>
cd <repository-directory>
./scripts/setup.sh
./scripts/run-all.sh
```

`setup.sh` checks Git, Docker CLI, Compose, DNS/HTTPS access to Apache, and a running Docker engine. If Docker Desktop is stopped, start it with `open -a Docker`, wait for “Engine running”, and rerun setup. If the app bundle is incomplete or Docker is missing, reinstall Docker Desktop from [Docker’s official Mac instructions](https://docs.docker.com/desktop/setup/install/mac-install/), open it and rerun setup. The script does not install system software or require administrator access. It builds the pinned HBase image.

`run-all.sh` repeats the setup checks safely, prepares the data, runs every Section 10 operation, and saves terminal output in `output/`. On first run, the real Alibaba dataset chunk may take time to download. The acquisition script prints its reported size first. It fetches only `MSCallGraph_0.tar.gz`; it never runs Alibaba’s full 25 GiB fetch script. If that official host cannot be reached, place an authorized extracted MSCallGraph CSV under `data/source/` and rerun.

## One command for each figure

Run after `./scripts/run-all.sh`. Each command replays the real operation and writes a fresh terminal log while leaving that output visible for a screenshot.

| Figure | Command | Terminal evidence |
|---|---|---|
| 29 | `./scripts/01-create-put.sh` | Demo CREATE, DESCRIBE, PUT and SCAN |
| 30 | `./scripts/02-bulk-load.sh` | ImportTsv/HFile load counters and table count |
| 31 | `./scripts/03-get-scan-count.sh` | A real GET, limited SCAN and COUNT |
| 32 | `./scripts/04-delete-restore.sh` | Snapshot, cell delete, row delete, counts and restore |
| 33 | `./scripts/05-query1.sh` | Service prefix AND response-time threshold |
| 34 | `./scripts/06-query2.sh` | RPC type AND response-time threshold |
| 35 | `./scripts/07-query3.sh` | Interface qualifier and response time below median |
| 36 | `./scripts/08-query4.sh` | OR of two upstream service prefixes |
| 37 | `./scripts/09-java.sh` | Java compile/run and shell count agreement |

The exact one-command instructions and screenshot placement are in [SCREENSHOT_GUIDE.md](SCREENSHOT_GUIDE.md). Screenshots are taken by the student from the visible terminal; this repository does not create screenshot images.

## Individual steps

```bash
./scripts/00-prepare.sh             # acquire one source chunk if needed, profile and clean
./scripts/01-create-put.sh          # Figure 29
./scripts/02-bulk-load.sh            # Figure 30; recreates only ms_callgraph
./scripts/03-get-scan-count.sh       # Figure 31
./scripts/04-delete-restore.sh       # Figure 32; touches only ms_callgraph and its named snapshot
./scripts/05-query1.sh               # Figure 33
./scripts/06-query2.sh               # Figure 34
./scripts/07-query3.sh               # Figure 35
./scripts/08-query4.sh               # Figure 36
./scripts/09-java.sh                 # Figure 37
```

The first run requires `00-prepare.sh` and `02-bulk-load.sh` before the queries. Each query selects its service IDs and thresholds from the prepared real slice. Rerunning the importer recreates the repository table, so it produces a clean repeatable load. The four query scripts are read-only. The delete/restore script replaces only its own snapshot before creating a fresh one.

## Data and evidence

The official source is Alibaba’s [cluster-trace-microservices-v2021 README](https://github.com/alibaba/clusterdata/blob/master/cluster-trace-microservices-v2021/README.md) and the one-chunk object URL in `scripts/acquire-data.py`. The project validates the actual CSV header and writes `data/processed/manifest.json`, a deterministic TSV, and query settings. Source and generated dataset files are intentionally excluded from Git; the manifest records source and cleaned-file SHA-256 checksums and observed slice details. Do not replace them with synthetic data for the report.

Every numbered operation stores combined stdout/stderr and an exit status in `output/`. These are actual logs created by running the command. Reading a saved log is a review; running its corresponding command re-executes HBase/Java and displays fresh results. A clean checkout starts with no claimed execution logs. Read [REPORT_SECTION_10.md](REPORT_SECTION_10.md) for design and the measured result fields, and [DEPENDENCIES.md](DEPENDENCIES.md) for pinned versions.

## Architecture and local access

The image uses Java bytecode HBase distribution on Temurin OpenJDK 11, so the container builds on Apple Silicon (`arm64`) and Intel (`amd64`) when Docker Desktop can pull its multi-architecture Java base image. HBase itself runs standalone, on one local process and local filesystem. This demonstrates HBase commands and filters, not multi-node operation or production availability. Port 16010 is bound only to `127.0.0.1`; the HBase RPC and ZooKeeper services are not published to the LAN. Persistent data stays in the Compose project-scoped `hbase_data` volume.

## Stop, reset and troubleshooting

```bash
./scripts/stop.sh
```

Stops only this Compose service and preserves its data. To discard only the Section 10 HBase database and cleaned derived slice:

```bash
./scripts/reset.sh
```

The reset removes this Compose project’s service/network/volume and clears `data/processed/`. It keeps any downloaded CSV/archive in `data/source/`. It does not prune or remove other Docker data. To also discard the source chunk, remove only this repository’s `data/source/` directory yourself.

Common issues:

- **Docker engine stopped:** run `open -a Docker`, wait for it to finish starting, rerun `./scripts/setup.sh`. If macOS reports that Docker.app has no executable, reinstall it using Docker’s official Mac instructions above.
- **DNS/network unavailable:** connect to the internet and rerun. Setup and acquisition fail with the URL and next step; no synthetic fallback exists.
- **No official download access:** provide an authorized, extracted CSV in `data/source/` and rerun `./scripts/00-prepare.sh`.
- **Insufficient Docker disk or memory:** free space in Docker Desktop and allocate at least 4 GB memory; 6 GB is preferable during ImportTsv. Do not run a global Docker prune.
- **Inspect HBase startup:** `docker compose logs --tail=120 hbase`; confirm `docker compose ps` reports healthy.
- **Import failure:** inspect `output/02-bulk-load.log` and the manifest schema. `Bad Lines` must be zero; the importer is configured to fail on malformed input.

## Commit and push

No remote is configured by this repository. Once you have repository access and set the remote URL:

```bash
git switch -c section-10-mscallgraph
git add README.md REPORT_SECTION_10.md SCREENSHOT_GUIDE.md DEPENDENCIES.md Dockerfile compose.yaml conf docker java scripts output figures
git commit -m "Complete Section 10 MSCallGraph HBase project"
git push -u origin section-10-mscallgraph
```

The dataset itself stays out of Git. Generated text logs and student screenshots can be added explicitly with `git add output figures` after reviewing them.
