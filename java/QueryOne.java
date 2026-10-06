import java.io.IOException;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.filter.*;
import org.apache.hadoop.hbase.util.Bytes;

/** Reproduces scripts/05-query1.sh: one UM prefix AND encoded RT > threshold. */
public final class QueryOne {
  public static void main(String[] args) throws Exception {
    if (args.length != 2) throw new IllegalArgumentException("Usage: QueryOne <upstream-service-id> <20-digit-rt-ord-threshold>");
    byte[] prefix = Bytes.toBytes(args[0] + "#");
    byte[] threshold = Bytes.toBytes(args[1]);
    Configuration conf = HBaseConfiguration.create();
    try (Connection connection = ConnectionFactory.createConnection(conf);
         Table table = connection.getTable(TableName.valueOf("ms_callgraph"))) {
      PrefixFilter byService = new PrefixFilter(prefix);
      SingleColumnValueFilter byRt = new SingleColumnValueFilter(
          Bytes.toBytes("metrics"), Bytes.toBytes("rt_ord"),
          CompareOperator.GREATER, new BinaryComparator(threshold));
      byRt.setFilterIfMissing(true);
      FilterList filters = new FilterList(FilterList.Operator.MUST_PASS_ALL, byService, byRt);
      Scan scan = new Scan().setFilter(filters)
          .addColumn(Bytes.toBytes("meta"), Bytes.toBytes("um"))
          .addColumn(Bytes.toBytes("meta"), Bytes.toBytes("dm"))
          .addColumn(Bytes.toBytes("meta"), Bytes.toBytes("rpctype"))
          .addColumn(Bytes.toBytes("metrics"), Bytes.toBytes("rt_ms"));
      long count = 0;
      try (ResultScanner scanner = table.getScanner(scan)) {
        for (Result result : scanner) {
          byte[] um = result.getValue(Bytes.toBytes("meta"), Bytes.toBytes("um"));
          byte[] dm = result.getValue(Bytes.toBytes("meta"), Bytes.toBytes("dm"));
          byte[] type = result.getValue(Bytes.toBytes("meta"), Bytes.toBytes("rpctype"));
          byte[] rt = result.getValue(Bytes.toBytes("metrics"), Bytes.toBytes("rt_ms"));
          if (um == null || dm == null || type == null || rt == null) {
            System.out.println("MISSING_PROJECTED_COLUMN row=" + Bytes.toStringBinary(result.getRow()));
            continue;
          }
          if (count < 5) {
            System.out.printf("JAVA_ROW key=%s um=%s dm=%s rpctype=%s rt_ms=%s%n",
                Bytes.toStringBinary(result.getRow()), Bytes.toString(um), Bytes.toString(dm),
                Bytes.toString(type), Bytes.toString(rt));
          }
          count++;
        }
      }
      System.out.println("JAVA_MATCHING_COUNT=" + count);
    }
  }
}
