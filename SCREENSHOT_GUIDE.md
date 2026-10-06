# Screenshot guide for Figures 29–37

Take each screenshot yourself from the visible terminal after <code>./scripts/run-all.sh</code> succeeds. Open Terminal at the repository root. Each command below reruns the real operations, prints the exact commands and their fresh HBase/Java output, and refreshes the corresponding <code>output/</code> transcript. Do not screenshot a saved-log viewer and describe it as a terminal execution. If you only inspect a log, that is review of a previous run; it does not re-execute HBase.

Save the nine genuine terminal screenshots under <code>figures/</code> using the exact filenames listed. Resize the terminal so the command and relevant output are readable; for long query output, capture the matching count and a few representative rows shown by the script.

| Figure | One copy-paste command | What should be visible | Screenshot file |
|---|---|---|---|
| 29 | <code>./scripts/01-create-put.sh</code> | CREATE and DESCRIBE of demo table, PUT cells, SCAN row | <code>figures/fig29_create_put.png</code> |
| 30 | <code>./scripts/02-bulk-load.sh</code> | Real ImportTsv input/counters, bad-line evidence, HFile load and loaded count | <code>figures/fig30_bulk_load.png</code> |
| 31 | <code>./scripts/03-get-scan-count.sh</code> | Real-row GET, five-row SCAN preview, full COUNT | <code>figures/fig31_get_scan_count.png</code> |
| 32 | <code>./scripts/04-delete-restore.sh</code> | Snapshot, deleted-cell remaining values, row deletion/count change, restored row/count | <code>figures/fig32_delete_restore.png</code> |
| 33 | <code>./scripts/05-query1.sh</code> | Actual service ID/threshold, filter command, preview and total count | <code>figures/fig33_query1.png</code> |
| 34 | <code>./scripts/06-query2.sh</code> | Actual RPC type/p75 threshold, AND filter, preview and total count | <code>figures/fig34_query2.png</code> |
| 35 | <code>./scripts/07-query3.sh</code> | Actual median, qualifier/value filters, preview and total count | <code>figures/fig35_query3.png</code> |
| 36 | <code>./scripts/08-query4.sh</code> | Actual two service IDs, OR filter, preview and total count | <code>figures/fig36_query4.png</code> |
| 37 | <code>./scripts/09-java.sh</code> | Shell count, Java compile/run, JAVA_MATCHING_COUNT and AGREEMENT | <code>figures/fig37_java.png</code> |

Do not create an image if that command fails. Correct the displayed runtime/network/dataset error, rerun the step, then take the screenshot after the successful output is visible. Figure 30 must show zero bad lines; if HBase omits a zero-valued counter, preserve the ImportTsv output and report that the counter was not emitted. Figure 37 must end with an AGREEMENT line.
