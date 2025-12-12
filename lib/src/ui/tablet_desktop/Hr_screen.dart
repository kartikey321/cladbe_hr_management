import 'package:cladbe_hr_management/src/ui/tablet_desktop/Holiday/Holiday_dashboard.dart';
import 'package:cladbe_hr_management/src/ui/tablet_desktop/attendanceDashboard/Attendance_dashboard.dart';
import 'package:cladbe_hr_management/src/ui/tablet_desktop/leave_management.dart/leaveManagement_screen.dart';
import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';
import 'Employee_shift/ShiftManagement.dart';

class HrScreen extends StatefulWidget {
  const HrScreen({
    super.key,
  });

  @override
  State<HrScreen> createState() => _HrScreenState();
}

class _HrScreenState extends State<HrScreen> {
  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);

  List<TabItem> hrFeatures = [
    const TabItem(label: 'Attendance Tracking', value: 'attendance_tracking'),
    const TabItem(label: 'Shift Management', value: 'shift_management'),
    const TabItem(label: 'Leave Management', value: 'leave_management'),
    const TabItem(label: 'Holidays', value: 'holidays'),
  ];

  dynamic _onTabSelected(int index, TabItem tab) {
    setState(() {
      _selectedIndex.value = index;
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppDefault.backgroundColor,
        body: Container(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: CustomAnimatedTabs(
              indicatorHeight: 10,
              selectedIndex: _selectedIndex,
              onTabSelected: _onTabSelected,
              tabItems: hrFeatures,
              widgets: const [
                AttendanceDashboard(),
                Align(
                  alignment: AlignmentGeometry.bottomLeft,
                  child: ShiftManagement(),
                ),
                Center(
                  child: LeaveManagementScreen(),
                ),
                HolidayDashboardScreen(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
