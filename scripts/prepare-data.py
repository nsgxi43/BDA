#!/usr/bin/env python3
"""Validate the real CSV and emit deterministic ImportTsv input and evidence."""
import csv, hashlib, json, pathlib
from collections import Counter
ROOT=pathlib.Path(__file__).resolve().parents[1]; SRC=ROOT/'data/source'; OUT=ROOT/'data/processed'; OUT.mkdir(parents=True,exist_ok=True)
csvs=sorted(SRC.rglob('*.csv'))
if not csvs: raise SystemExit('No CSV found. Run scripts/acquire-data.py first.')
source=csvs[0]; required=['timestamp','traceid','rpcid','um','rpctype','interface','dm','rt']
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
 return h.hexdigest()
reject=Counter(); rows=[]; keys=set(); header=None
with source.open('r',encoding='utf-8-sig',newline='') as f:
 reader=csv.DictReader(f)
 header=reader.fieldnames or []
 absent=[x for x in required if x not in header]
 if absent: raise SystemExit(f'CSV schema mismatch: missing {absent}; found {header}')
 for line,row in enumerate(reader,2):
  if None in row: reject['extra_fields']+=1; continue
  vals={k:(row.get(k) if row.get(k) is not None else '') for k in required}
  if any(not vals[k] or vals[k].isspace() for k in required): reject['missing_required_field']+=1; continue
  if any(any(c in vals[k] for c in '\t\r\n') for k in required): reject['tab_or_newline_in_field']+=1; continue
  try:
   ts=int(vals['timestamp']); rt=int(vals['rt'])
   if ts<0: reject['negative_timestamp']+=1; continue
   if ts>9999999999999: reject['timestamp_exceeds_13_digit_key_field']+=1; continue
   if rt<-(2**63) or rt>(2**63)-1: reject['rt_out_of_int64_range']+=1; continue
  except ValueError: reject['malformed_integer_timestamp_or_rt']+=1; continue
  if any('#' in vals[k] for k in ('um','traceid','rpcid')): reject['row_key_delimiter_in_identifier']+=1; continue
  key=f"{vals['um']}#{ts:013d}#{vals['traceid']}#{vals['rpcid']}"
  if key in keys: reject['duplicate_row_key']+=1; continue
  keys.add(key)
  rows.append((vals,ts,rt,key))
  if len(rows)>=50000: break
if not rows: raise SystemExit(f'No valid rows. Rejections: {dict(reject)}')
# Row-key uniqueness is guaranteed by full UM/time/trace/rpc components and checked above.
ts_values=[r[1] for r in rows]; rts=sorted(r[2] for r in rows)
um_counts=Counter(r[0]['um'] for r in rows); rp_counts=Counter(r[0]['rpctype'] for r in rows)
primary=um_counts.most_common(1)[0][0]; other=next((u for u,n in um_counts.most_common() if u!=primary),primary)
rpc=rp_counts.most_common(1)[0][0]
p95=rts[min(len(rts)-1, int(.95*(len(rts)-1)))]; threshold=p95
median=rts[len(rts)//2]; p75=rts[min(len(rts)-1, int(.75*(len(rts)-1)))]; p25=rts[min(len(rts)-1, int(.25*(len(rts)-1)))]
encoded=lambda n:f'{n+9223372036854775808:020d}'
if any(encoded(a)>encoded(b) for a,b in zip(rts,rts[1:])):
 raise SystemExit('Response-time encoding failed signed numeric lexicographic-order validation.')
tsv=OUT/'mscallgraph.tsv';
with tsv.open('w',encoding='utf-8',newline='') as f:
 for v,ts,rt,key in rows:
  cols=[key,v['traceid'],v['rpcid'],v['um'],v['dm'],v['rpctype'],v['interface'],str(ts),encoded(rt),str(rt)]
  f.write('\t'.join(cols)+'\n')
archive=SRC/'MSCallGraph_0.tar.gz'
manifest={
 'source_origin':'official_alibaba_chunk_0' if archive.exists() else 'user_supplied_csv',
 'source_url':'https://aliopentrace.oss-cn-beijing.aliyuncs.com/v2021MicroservicesTraces/MSCallGraph/MSCallGraph_0.tar.gz' if archive.exists() else None,
 'source_archive_sha256':sha(archive) if archive.exists() else None,
 'source_filename':str(source.relative_to(ROOT)), 'source_sha256':sha(source), 'source_schema':header,
 'sampling_rule':'First 50,000 valid rows in source-file order; skip invalid rows; stop after 50,000 retained records.',
 'percentile_rule':'Sort signed rt values and select index floor(p * (N - 1)); ties retain equal thresholds.',
 'max_rows':50000,'retained_rows':len(rows),'rejected_rows':dict(reject),'rejected_total':sum(reject.values()),
 'time_range_ms':[min(ts_values),max(ts_values)], 'row_key_unique':len(keys)==len(rows),
 'duplicate_policy':'retain first occurrence of composite row key; reject later duplicates.',
 'negative_rt_policy':'preserve; the upstream source documents signed UM/DM RPC response times.',
 'missing_policy':'reject a row if any required field is empty; IDs are otherwise preserved verbatim.',
 'malformed_policy':'reject malformed integer timestamp/rt and out-of-range values; extra CSV fields are rejected.',
 'tsv_filename':'data/processed/mscallgraph.tsv','tsv_rows':len(rows),'tsv_sha256':sha(tsv),
 'query':{'upstream_service':primary,'second_service':other,'rpc_type':rpc,'rt_threshold_ms':threshold,'rt_threshold_encoded':encoded(threshold),'p75_ms':p75,'p75_encoded':encoded(p75),'median_ms':median,'median_encoded':encoded(median),'p25_ms':p25,'p25_encoded':encoded(p25)},
 'rt_encoding':'metrics:rt_ord = rt + 2^63, fixed-width 20 digit decimal UTF-8. Lexicographic byte order equals signed int64 numeric order; metrics:rt_ms stores original signed decimal.',
 'rt_encoding_order_verified':True}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(OUT/'query.env').write_text('UPSTREAM='+primary+'\nSECOND_SERVICE='+other+'\nRPC_TYPE='+rpc+'\nRT_THRESHOLD='+str(threshold)+'\nRT_THRESHOLD_ENCODED='+encoded(threshold)+'\nP75_ENCODED='+encoded(p75)+'\nMEDIAN_ENCODED='+encoded(median)+'\nP25_ENCODED='+encoded(p25)+'\n')
print(json.dumps(manifest,indent=2))
