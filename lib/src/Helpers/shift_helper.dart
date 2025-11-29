import 'package:cladbe_shared/cladbe_shared.dart';

class ShiftHelper {
  static Future<void> getAllShifts({required String companyId}) async {
    WeeklyShiftContoller(companyId: companyId).getData();
  }

  static Future<void> addShift(
      {required String companyId,
      required WeeklyShiftModel weeklyShift}) async {
    WeeklyShiftContoller(companyId: companyId).addData(
      weeklyShift,
      weeklyShift.id,
    );
  }
}
