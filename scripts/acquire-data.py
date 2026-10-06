#!/usr/bin/env python3
"""Use a supplied MSCallGraph CSV when present, otherwise fetch official chunk 0."""
import glob, os, pathlib, subprocess, sys, urllib.request
ROOT = pathlib.Path(__file__).resolve().parents[1]
src = ROOT / 'data/source'
csvs = sorted(src.rglob('*.csv'))
if csvs:
    print('Using repository/user-supplied CSV:', csvs[0].relative_to(ROOT))
    if len(csvs) > 1: print('Additional CSVs ignored:', ', '.join(str(p.relative_to(ROOT)) for p in csvs[1:]))
    sys.exit(0)
url = 'https://aliopentrace.oss-cn-beijing.aliyuncs.com/v2021MicroservicesTraces/MSCallGraph/MSCallGraph_0.tar.gz'
target = src / 'MSCallGraph_0.tar.gz'
if target.exists():
    print('Using previously downloaded official chunk:', target.relative_to(ROOT)); sys.exit(0)
req = urllib.request.Request(url, method='HEAD')
try:
    with urllib.request.urlopen(req, timeout=20) as response:
        size = response.headers.get('Content-Length')
except Exception:
    size = None
if not size:
    try:
        req = urllib.request.Request(url, headers={'Range':'bytes=0-0'})
        with urllib.request.urlopen(req, timeout=20) as response:
            size = response.headers.get('Content-Length')
            content_range = response.headers.get('Content-Range','')
            if '/' in content_range: size = content_range.rsplit('/',1)[1]
    except Exception as e:
        raise SystemExit(f'Cannot determine official chunk size or reach Alibaba URL {url}: {e}\nPlace one official MSCallGraph CSV in data/source/ and rerun.')
if not size or not str(size).isdigit():
    raise SystemExit(f'Alibaba did not report a verifiable expected size for {url}; download was not started. Place an official CSV under data/source/ and rerun.')
n=int(size)
print(f'Official chunk size: {n:,} bytes ({n/1_000_000:.1f} MB decimal). This is one of 145 MSCallGraph chunks; official full directory is about 25 GiB.')
src.mkdir(parents=True, exist_ok=True)
tmp = target.with_suffix('.tar.gz.part')
try:
    urllib.request.urlretrieve(url, tmp)
    tmp.replace(target)
except Exception as e:
    tmp.unlink(missing_ok=True); raise SystemExit(f'Chunk download failed: {e}')
print('Downloaded:', target.relative_to(ROOT), target.stat().st_size, 'bytes')
subprocess.run(['tar', '-tzf', str(target)], check=True)
subprocess.run(['tar', '-xzf', str(target), '-C', str(src)], check=True)
csvs = sorted(src.rglob('*.csv'))
if not csvs: raise SystemExit('Official archive contained no CSV; inspect the archive and provide its extracted CSV under data/source/.')
print('Extracted CSV:', csvs[0].relative_to(ROOT))
