import 'package:cladbe_hr_management/src/ui/tablet_desktop/attendanceDashboard/attendance_dashboard_screen.dart';
import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';

class AttendanceDashboard extends StatefulWidget {
  const AttendanceDashboard({super.key});

  @override
  State<AttendanceDashboard> createState() => _AttendanceDashboardState();
}

class _AttendanceDashboardState extends State<AttendanceDashboard> {
  List<Employee> allEmployee = [];
  @override
  void initState() {
    super.initState();
    fetchEmployee();
  }

  Future<void> fetchEmployee() async {
    allEmployee = await EmployeeData.getData('C');
    // Initialize displayedEmployees with all employees (unselected initially)
    setState(() {
      // displayedEmployees = List.from(allEmployee);
    });
    // Animate initial items
  }

  @override
  Widget build(BuildContext context) {
    return AttendanceDashboardScreen(
      employees: allEmployee,
      companyId: context.getCompanyId(),
    );
  }
}
