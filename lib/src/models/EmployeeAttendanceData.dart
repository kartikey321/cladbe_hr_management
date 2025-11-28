// Model to hold employee with attendance data
import 'package:cladbe_shared/cladbe_shared.dart';

class EmployeeAttendanceData {
  final Employee employee;
  final AttendanceLog? log;
  final String status;
  final String? checkInTime;
  final String? checkOutTime;
  final String? totalTime;

  EmployeeAttendanceData({
    required this.employee,
    this.log,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.totalTime,
  });
}
