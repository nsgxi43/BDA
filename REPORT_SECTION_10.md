# 10 Diya Bhat: Individual Contribution

**Roll number:** CB.SC.U4CSE23319  
**Assigned dataset/table:** Alibaba MSCallGraph / <code>ms_callgraph</code>

This contribution targets Figures 29–37 in the supplied report. All measurements below must come from a successful run of this repository on its real dataset input. The current workspace could not reach external hosts and its Docker engine was stopped, so no HBase result, dataset row count, query result, Java result, or screenshot is claimed as observed here. Run <code>./scripts/run-all.sh</code>; the corresponding real outputs will be saved under <code>output/</code>. Never replace these fields with estimates. The prepared implementation must be run and reviewed by the submitter before submission.

## 10.1 Dataset Slice and Attributes

The source is one official Alibaba <code>MSCallGraph_0.tar.gz</code> chunk from the <code>cluster-trace-microservices-v2021</code> release. The official README gives the complete MSCallGraph set as approximately 25 GiB over 145 chunks; the acquisition script requests only chunk 0 and prints the server’s reported size before download. If a supplied CSV already exists under <code>data/source/</code>, the first path in sorted order is selected instead. The exact path, source hash, actual parsed schema and cleaned hash are recorded in <code>data/processed/manifest.json</code>.

The deterministic rule keeps up to 50,000 valid unique rows in original CSV order. It uses Python’s CSV reader with quoting and UTF-8 BOM handling, validates the actual header, and stops once the target count is reached. The manifest counts encountered rejected rows by reason before that stopping point. It rejects missing required fields, extra CSV fields, tab/newline field values, invalid integer timestamp/rt, negative timestamps, rt outside signed 64-bit range, and later duplicate row keys. Negative <code>rt</code> is retained because the data owner documents signed RPC observations: upstream latency is positive and downstream latency may be stored as its negative. Full identifiers are kept.

| Source field | Observed type | Meaning and handling |
|---|---|---|
| <code>timestamp</code> | integer | Millisecond trace timestamp; nonnegative, retained unchanged |
| <code>traceid</code> | string | Trace identifier; preserve exactly |
| <code>rpcid</code> | string | Call path identifier; preserve punctuation and exact text |
| <code>um</code> | string | Upstream service identifier; preserve exactly and use as row-key prefix |
| <code>rpctype</code> | string | Communication type such as RPC/HTTP/DB/MC as actually present |
| <code>interface</code> | string | Called interface identifier; preserve exactly |
| <code>dm</code> | string | Downstream service identifier; preserve exactly |
| <code>rt</code> | signed integer | Response time in ms; original value stored as decimal and sortable encoding stored separately |

**Measured slice values (not observed in this workspace):** source file/hash, retained rows, rejected counts, timestamp range and cleaned TSV hash are generated in <code>output/00-dataset-profile.log</code> and <code>data/processed/manifest.json</code> by the first run. The actual values must be copied from those records after execution. The source contains hashed service names; those are identifiers, not human-readable service names.

## 10.2 HBase Table Design

The data table is <code>ms_callgraph</code>, with two families:

| Family | Qualifiers | Reason |
|---|---|---|
| <code>meta</code> | <code>traceid</code>, <code>rpcid</code>, <code>um</code>, <code>dm</code>, <code>rpctype</code>, <code>interface</code> | Identifiers and call relationship attributes, queried together |
| <code>metrics</code> | <code>timestamp</code>, <code>rt_ord</code>, <code>rt_ms</code> | Numeric observations isolated from descriptive call metadata |

<code>rt_ms</code> retains the original signed integer for readable output. <code>rt_ord</code> stores <code>rt + 2^63</code> as exactly 20 decimal digits. With a constant width and nonnegative biased values, unsigned UTF-8 byte ordering matches signed int64 numeric ordering. Every sample is checked against this mapping during preprocessing; the 20-digit encoding is also used for filter comparators. Variable-width decimal text would not have safe numeric comparisons.

The table is created before ImportTsv bulk output is loaded. Column families are intentionally limited to two to avoid one family per field. The separate <code>section10_demo</code> table is used only for the Figure 29 CREATE/DESCRIBE/PUT/SCAN example.

## 10.3 Row-Key Design

Pattern:

    <full-um>#<timestamp-zero-padded-to-13-digits>#<full-traceid>#<full-rpcid>

The upstream service is the leading key component, so a PrefixFilter can select one service. Timestamp sorts lexically within that service because it is a fixed-width, zero-padded decimal field. The full trace ID and RPC ID disambiguate same-time calls and preserve call-level identity. The current sample verifies key uniqueness by inserting every candidate into a set and rejecting later collisions; the manifest records the uniqueness check. For example, the actual generated example must be copied from the first key in <code>data/processed/mscallgraph.tsv</code> after preparation.

This layout supports upstream service scans and time-order traversal. A direct timestamp range across all services or a downstream-service query is not a contiguous range and requires a scan/filter or a second index table. Very high-volume upstream prefixes may also concentrate reads. No abbreviated hash prefix is used, and all IDs remain available in <code>meta</code>.

## 10.4 HBase Shell Commands

Every command below has an executable counterpart under <code>scripts/</code>. The scripts echo commands, show returned output, stop on errors and save the transcript with exit status. For current measurements see logs after execution.

### 10.4.1 Table creation and insertion — Figure 29

<code>./scripts/01-create-put.sh</code> recreates only the demo table, runs CREATE, DESCRIBE, several PUTs and a limited SCAN. The exact shell statements and observed response are in <code>output/01-create-put.log</code>. The imported dataset table is created separately by the bulk-load step.

### 10.4.2 Bulk load — Figure 30

<code>./scripts/02-bulk-load.sh</code> recreates only <code>ms_callgraph</code>, runs <code>ImportTsv</code> with <code>-Dimporttsv.bulk.output</code>, then <code>LoadIncrementalHFiles</code>. Its TSV uses the columns <code>HBASE_ROW_KEY,meta:traceid,meta:rpcid,meta:um,meta:dm,meta:rpctype,meta:interface,metrics:timestamp,metrics:rt_ord,metrics:rt_ms</code>. <code>importtsv.skip.bad.lines=false</code> makes malformed rows fail the run. The ImportTsv counters, bad-line counter where emitted, HFile loader output and HBase row count appear in <code>output/02-bulk-load.log</code>.

**Measured result:** pending actual ImportTsv execution. Expected TSV input is exactly the manifest’s retained row count; do not describe this as a loaded count until ImportTsv and the subsequent HBase count both finish successfully. The implementation must report zero Bad Lines. If a Hadoop version omits a zero-valued counter in its output, record that the counter was not emitted and use the HBase count as the loaded-row evidence.

### 10.4.3 GET, SCAN and COUNT — Figure 31

<code>./scripts/03-get-scan-count.sh</code> takes a key from the first cleaned real TSV record, performs GET, <code>SCAN {LIMIT =&gt; 5}</code> and an unrestricted COUNT. <code>output/03-get-scan-count.log</code> contains the actual key and response. The count is the total table count; the scan is only a five-row preview.

### 10.4.4 DELETE, DELETEALL and restore — Figure 32

<code>./scripts/04-delete-restore.sh</code> snapshots <code>ms_callgraph</code> as <code>section10_before_delete</code>; deletes the <code>metrics:rt_ms</code> cell in the first sample row and confirms remaining cells; deletes all cells in that row; compares counts; disables the table, restores the snapshot, reenables it and verifies the row and count. This operation touches only the repository’s table and named snapshot. A rerun first removes its own snapshot.

**Measured result:** table count before deletion, after DELETEALL, and after restore are printed in <code>output/04-delete-restore.log</code>. Required relationship: after deletion the count is lower by one; after restore the original row and count return. No run was possible in the current environment.

## 10.5 Filters and Application Queries

The profile chooses the most frequent upstream (<code>um</code>), a second distinct upstream if one exists, the most frequent <code>rpctype</code>, and sample percentile thresholds. All are values in <code>data/processed/manifest.json</code>. Byte comparisons use <code>metrics:rt_ord</code>, never variable-width <code>rt_ms</code>. SingleColumnValueFilters set <code>filterIfMissing=true</code>, so a row missing the tested metric or type is excluded intentionally. Projected <code>COLUMNS</code> do not remove filter inputs from the server-side row evaluation.

The scripts show a five-row preview followed by a full count using the same filter. Preview size is not the match count. The exact service IDs, threshold values, actual counts, result rows and elapsed times are run-specific and appear in logs. They are unverified until the project runs successfully.

### 10.5.1 Query 1 — Figure 33

**Question:** Which calls from the most frequent upstream service exceed the measured sample 95th-percentile RT threshold?

**Command:** <code>./scripts/05-query1.sh</code> (echoes its exact scan and count commands).

**Filters:** <code>PrefixFilter</code> on <code>&lt;um&gt;#</code> AND <code>SingleColumnValueFilter</code> with <code>metrics:rt_ord GREATER threshold</code>; missing RT values are excluded. This combines a row-key access pattern with a numeric comparison.

**Results and interpretation:** actual ID, threshold, full matching count and limited rows are unverified here. A match identifies calls from that selected upstream service whose signed recorded <code>rt</code> is above the sample’s p95. Review the real rows in <code>output/05-query1.log</code>.

### 10.5.2 Query 2 — Figure 34

**Question:** Which calls of the most common observed RPC type exceed the sample 75th percentile?

**Command:** <code>./scripts/06-query2.sh</code>.

**Filters:** two <code>SingleColumnValueFilter</code>s combined with <code>MUST_PASS_ALL</code>: <code>meta:rpctype EQUAL selected-type</code> AND <code>metrics:rt_ord GREATER selected-p75</code>. Both use <code>filterIfMissing=true</code>.

**Results and interpretation:** actual count and returned records require the real run. The query isolates slower calls for one observed communication type; it is a full table filter scan.

### 10.5.3 Query 3 — Figure 35

**Question:** Which rows include the interface qualifier and have RT below the measured median?

**Command:** <code>./scripts/07-query3.sh</code>.

**Filters:** <code>ColumnPrefixFilter('interface')</code> AND <code>SingleColumnValueFilter(metrics:rt_ord LESS median)</code>. Only <code>meta:interface</code> is projected because ColumnPrefixFilter excludes nonmatching qualifiers from the returned cells. The value filter still evaluates <code>metrics:rt_ord</code> server-side; missing RT is excluded.

**Results and interpretation:** actual median/count/preview are unverified here. Returned calls lie below the dataset’s signed RT median and contain interface metadata.

### 10.5.4 Query 4 — Figure 36

**Question:** Which calls have either of the two most frequent distinct upstream services?

**Command:** <code>./scripts/08-query4.sh</code>.

**Filters:** two <code>PrefixFilter</code>s combined using <code>MUST_PASS_ONE</code> (OR); selected columns show both endpoints and trace/RPC identifiers. If only one upstream exists, the two prefixes collapse to that one service and this limitation is shown in the manifest.

**Results and interpretation:** actual IDs, count and representative records are unverified until execution. This query compares call populations for two measured high-volume upstreams.

## 10.6 Java API Implementation — Figure 37

<code>java/QueryOne.java</code> reproduces Query 1 through the HBase Java client from the same HBase distribution. It uses a <code>PrefixFilter</code> AND a <code>SingleColumnValueFilter</code> with a <code>BinaryComparator</code>, explicit <code>setFilterIfMissing(true)</code>, column projection, try-with-resources for connection/table/scanner, and explicit handling of absent projected values. <code>scripts/09-java.sh</code> compiles with the container’s HBase classpath, runs the program against the same table, obtains the Query 1 shell count and fails if the result counts differ.

The full Java source is <a href="java/QueryOne.java">java/QueryOne.java</a>. The compile command is <code>javac -cp "$(hbase classpath)" -d /workspace/output/java /workspace/java/QueryOne.java</code>; the run command is printed by the script. Actual compile output, sample rows, shell count, Java count and agreement are unverified here and will be saved to <code>output/09-java.log</code> only after a successful run.

## 10.7 Results and Interpretation

The artifact measures call relationships and signed response-time observations in a reproducibly selected slice. The prefix key orders each upstream service’s calls by timestamp and makes service-prefix access convenient. Column families separate relationship metadata from measured values. The encoded metric allows bytewise HBase filters to apply correct numeric comparisons. The four filter queries illustrate key-prefix, qualifier and value filtering, AND/OR composition, and limited previews versus complete counts. Java Query 1 should return exactly the same count as its shell equivalent; <code>09-java.sh</code> enforces that comparison.

**Observed findings:** no dataset or HBase run could be completed in the current environment, so no numerical finding is asserted. After <code>./scripts/run-all.sh</code>, replace this note with the actual retained/loaded count, time range, query counts, deletion/restore counts and Java agreement from <code>output/</code> and <code>data/processed/manifest.json</code>.

**Limitations:** only up to 50,000 valid rows from a single source chunk are used, so results describe that slice and not all 25 GiB of call-graph data. Service IDs are hashed. HBase runs standalone on one host; there is no distributed RegionServer behavior or production-scale performance claim. Prefix scans benefit the upstream-service access path; downstream and arbitrary time-only queries can require scans. The authoring Mac had a Docker CLI but its Docker Desktop bundle could not launch because its executable was missing; DNS also failed for the Apache archive host. Thus image build, dataset preparation, ImportTsv, all HBase commands, Java compilation/agreement, and second-run verification remain unverified here.
