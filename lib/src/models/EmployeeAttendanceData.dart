import 'package:cladbe_shared/cladbe_shared.dart';

class EmployeeAttendanceData {
  final Employee employee;
  final AttendanceLog? log; // the primary log (check-in) or null
  final String status;
  final String? checkInTime;
  final String? checkOutTime;
  final String? totalTime;
  final bool isLate;

  EmployeeAttendanceData({
    required this.employee,
    required this.log,
    required this.status,
    required this.checkInTime,
    required this.checkOutTime,
    required this.totalTime,
    this.isLate = false,
  });
}
