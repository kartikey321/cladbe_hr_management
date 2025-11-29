import 'package:cladbe_shared/cladbe_shared.dart';

class ShiftHelper {
  static Future<List<WeeklyShiftModel>> getAllShifts({
    required String companyId,
  }) {
    return WeeklyShiftContoller(companyId: companyId).getData();
  }

  static Future<void> addShift(
      {required String companyId,
      required WeeklyShiftModel weeklyShift}) async {
    WeeklyShiftContoller(companyId: companyId).addData(
      weeklyShift,
      weeklyShift.id,
    );
  }

  static Future<void> updateShift({
    required String companyId,
    required String weekShiftId,
    required Map<String, dynamic> shiftUpdates,
  }) async {
    WeeklyShiftContoller(companyId: companyId).updateField(
      shiftUpdates,
      weekShiftId,
    );
  }

  static Stream<List<WeeklyShiftModel>> getWeeklyShiftDataStream(
      String companyId,
      {List<DataFilter>? filters,
      int? limit}) {
    return WeeklyShiftContoller(companyId: companyId).getDataStream(
        filters: filters != null
            ? [
                DataFilterWrapper(
                    filterWrapperType: DataFilterWrapperType.and,
                    filters: filters)
              ]
            : null,
        limit: limit);
  }
}
