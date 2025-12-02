import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:cladbe_shared/src/models/Attendance/Holiday/holiday.dart';

class HolidaysHelper {
  static Future<List<HolidayModel>> getAllHoliday({
    required String companyId,
  }) {
    return HolidayContoller(companyId: companyId).getData();
  }

  static Future<void> addHoliday(
      {required String companyId, required HolidayModel holiday}) async {
    HolidayContoller(companyId: companyId).addData(
      holiday,
      holiday.id,
    );
  }

  static Future<void> updateHoliday({
    required String companyId,
    required String holidayId,
    required Map<String, dynamic> holidayUpdates,
  }) async {
    HolidayContoller(companyId: companyId).updateField(
      holidayUpdates,
      holidayId,
    );
  }

  static Future<void> deleteHoliday(
      {required String companyId, required String holidayId}) async {
    HolidayContoller(companyId: companyId).deleteDocument(
      holidayId,
    );
  }

  static Stream<List<HolidayModel>> getHolidayDataStream(String companyId,
      {List<DataFilter>? filters, int? limit}) {
    return HolidayContoller(companyId: companyId).getDataStream(
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
