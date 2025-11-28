import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:cladbe_shared/sql_client.dart';

class AttendanceLogHelper {
  // Get stream data from PostgreSQL
  static LivePager<AttendanceLog> getStreamData(
    String companyId, {
    List<SqlDataFilter>? filters,
    int? limit,
    SqlDataFilterWrapper? filterWrapper,
  }) {
    print("getStreamData called with filters: ${filters?.length ?? 0}");

    final controller = AttendanceLogController(companyId: companyId);

    final subscription = controller.getPager(
      limit: limit ?? 10,
      orderKeys: [
        const OrderKeySpec('timestamp', OrderSort.DESC_NULLS_LAST),
      ],
      rpc: SqlClient.instance.rpcClient,
      idOf: (m) => m.id,
      filter: SqlDataFilterWrapper(
        filterWrapperType: SQLFilterWrapperType.and,
        filters: [
          filterWrapper ??
              const SqlDataFilterWrapper(
                filterWrapperType: SQLFilterWrapperType.and,
                filters: [],
              )
        ],
      ),
    );

    print("Created subscription with filter: ${SqlDataFilterWrapper(
      filterWrapperType: SQLFilterWrapperType.and,
      filters: filters ?? [],
    )}");

    return subscription;
  }

  // Get data page from PostgreSQL
  static Future<DataPage<AttendanceLog>> getData(
    String companyId,
    String id, {
    List<SqlDataFilter>? filters,
    int? limit,
  }) async {
    return await AttendanceLogController(companyId: companyId).getDataFirstPage(
      filter: SqlDataFilterWrapper(
        filterWrapperType: SQLFilterWrapperType.and,
        filters: filters ?? [],
      ),
      limit: limit,
    );
  }
}
