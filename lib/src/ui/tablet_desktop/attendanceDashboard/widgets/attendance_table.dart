import 'package:cladbe_hr_management/src/models/EmployeeAttendanceData.dart';
import 'package:flutter/material.dart';
import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:intl/intl.dart';
import '../attendance_dashboard_screen.dart';

class AttendanceTable extends StatelessWidget {
  final List<EmployeeAttendanceData> attendanceData;

  const AttendanceTable({
    super.key,
    required this.attendanceData,
  });

  @override
  Widget build(BuildContext context) {
    // Sort attendance data alphabetically by employee name
    final sortedData = List<EmployeeAttendanceData>.from(attendanceData)
      ..sort((a, b) => a.employee.name
          .toLowerCase()
          .compareTo(b.employee.name.toLowerCase()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Header
        _buildTableHeader(),
        const SizedBox(height: 16),
        // Table Rows
        ...sortedData.map((data) => _buildTableRow(data)),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D23),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildHeaderCell('ID', flex: 1),
          _buildHeaderCell('Name', flex: 2),
          _buildHeaderCell('Date', flex: 2),
          _buildHeaderCell('Check-in Time', flex: 2),
          _buildHeaderCell('Check-out Time', flex: 2),
          _buildHeaderCell('Total Time', flex: 2),
          _buildHeaderCell('Status', flex: 2),
          _buildHeaderCell('Salary', flex: 1),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF8B8D97),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTableRow(EmployeeAttendanceData data) {
    final employee = data.employee;
    final date = data.log != null
        ? DateFormat('MMM dd, yyyy').format(data.log!.timestamp)
        : DateFormat('MMM dd, yyyy').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1C1D23),
            Color(0xFF2C2D35),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF3A3B43),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildCell(employee.empID, flex: 1),
          _buildCellWithAvatar(
            employee.name,
            employee.photo,
            flex: 2,
          ),
          _buildCell(date, flex: 2),
          _buildCell(data.checkInTime ?? '-', flex: 2),
          _buildCell(data.checkOutTime ?? '-', flex: 2),
          _buildCell(data.totalTime ?? '-', flex: 2),
          _buildStatusCell(data.status, flex: 2),
          _buildCell(employee.designation ?? '-', flex: 1),
        ],
      ),
    );
  }

  Widget _buildCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsetsGeometry.only(left: 10),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildCellWithAvatar(String name, AppDocument? photo, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 32,
              height: 32,
              child: photo != null
                  ? FileDisplay(document: photo)
                  : Container(
                      color: const Color(0xFF3A3B43),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCell(String status, {int flex = 1}) {
    Color statusColor;
    String statusText = status;

    switch (status.toLowerCase()) {
      case 'present':
        statusColor = const Color(0xFF34C759);
        break;
      case 'absent':
        statusColor = const Color(0xFFFF3B30);
        break;
      case 'on break':
        statusColor = const Color(0xFFFFCC00);
        break;
      case 'checked out':
        statusColor = const Color(0xFF5E7CE2);
        break;
      case 'not checked in yet':
        statusColor = const Color(0xFFFFA500);
        break;
      default:
        statusColor = const Color(0xFF8B8D97);
    }

    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
