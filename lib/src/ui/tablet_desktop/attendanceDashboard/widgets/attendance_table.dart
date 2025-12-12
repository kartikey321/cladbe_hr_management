import 'package:flutter/material.dart';
import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:intl/intl.dart';

class AttendanceTable extends StatelessWidget {
  final List<EmployeeAttendanceData> attendanceData;
  const AttendanceTable({super.key, required this.attendanceData});

  @override
  Widget build(BuildContext context) {
    final sortedData = List<EmployeeAttendanceData>.from(attendanceData)
      ..sort((a, b) => a.employee.name
          .toLowerCase()
          .compareTo(b.employee.name.toLowerCase()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        const SizedBox(height: 10),
        ...sortedData.map((d) => _row(d)),
      ],
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    return _tableCard(
      Row(children: [
        _headerCell("ID", flex: 1),
        _headerCell("Name", flex: 3),
        _headerCell("Date", flex: 2),
        _headerCell("Check-In", flex: 2),
        _headerCell("Check-Out", flex: 2),
        _headerCell("Total", flex: 2),
        _headerCell("Status", flex: 2),
        _headerCell("Late", flex: 1),
      ]),
    );
  }

  // ---------------- ROW ----------------
  Widget _row(EmployeeAttendanceData data) {
    final e = data.employee;
    final localTime = data.log?.timestamp.toLocal();
    final date =
        localTime != null ? DateFormat('MMM dd, yyyy').format(localTime) : "-";

    return _tableCard(
      Row(children: [
        _textCell(e.empID, flex: 1),
        _avatarCell(e.name, e.photo, flex: 3),
        _textCell(date, flex: 3),
        _textCell(data.checkInTime ?? '-', flex: 3),
        _textCell(data.checkOutTime ?? '-', flex: 2),
        _textCell(data.totalTime ?? '-', flex: 2),
        _statusCell(data.status, flex: 2),
        _lateCell(data.isLate, flex: 2),
      ]),
    );
  }

  // ---------------- BASIC CELL BUILDERS ----------------
  Widget _headerCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF8B8D97),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _textCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  Widget _avatarCell(String name, AppDocument? photo, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Row(children: [
        ClipOval(
          child: SizedBox(
            width: 30,
            height: 30,
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
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  // ---------------- STATUS BADGE ----------------
  Widget _statusCell(String status, {int flex = 1}) {
    Color color;
    switch (status.toLowerCase()) {
      case 'present':
        color = const Color(0xFF34C759);
        break;
      case 'checked out':
        color = const Color(0xFF5E7CE2);
        break;
      case 'absent':
        color = const Color(0xFFFF3B30);
        break;
      case 'on break':
        color = const Color(0xFFFFCC00);
        break;
      default:
        color = const Color(0xFF8B8D97);
    }

    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.only(left: 15, right: 15),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          status,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ---------------- LATE BADGE ----------------
  Widget _lateCell(bool isLate, {int flex = 1}) {
    if (!isLate) {
      return Expanded(
        flex: flex,
        child: const Center(
            child: Text('-', style: TextStyle(color: Color(0xFF8B8D97)))),
      );
    }

    const color = Color(0xFFFFA500);

    return Expanded(
      flex: flex,
      child: Container(
        width: 60,
        height: 30,
        margin: const EdgeInsets.only(left: 15, right: 15),
        // padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12)),
        child:
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 16),
          SizedBox(width: 5),
          Flexible(
            child: Text("Late",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  // ---------------- CARD WRAPPER ----------------
  Widget _tableCard(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1D23), Color(0xFF2C2D35)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: const Color(0xFF3A3B43)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}
