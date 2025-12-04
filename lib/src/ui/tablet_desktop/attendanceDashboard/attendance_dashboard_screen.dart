import 'dart:io';

import 'package:cladbe_hr_management/src/Helpers/attendance_log_helper.dart';
import 'package:cladbe_hr_management/src/Helpers/shift_helper.dart';
import 'package:cladbe_hr_management/src/models/EmployeeAttendanceData.dart';
import 'package:cladbe_hr_management/src/ui/tablet_desktop/attendanceDashboard/exportAttendance.dart';
import 'package:flutter/material.dart';
import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:cladbe_shared/sql_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'widgets/gradient_container.dart';
import 'widgets/stat_card.dart';
import 'widgets/attendance_table.dart';
import 'package:path_provider/path_provider.dart';

class AttendanceDashboardScreen extends StatefulWidget {
  final List<Employee> employees;
  final String companyId;

  const AttendanceDashboardScreen({
    super.key,
    required this.employees,
    required this.companyId,
  });

  @override
  State<AttendanceDashboardScreen> createState() =>
      _AttendanceDashboardScreenState();
}

class _AttendanceDashboardScreenState extends State<AttendanceDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = ServerTimeService.instance.currentServerTime;
  LivePager<AttendanceLog>? _logsPager;
  String selectedStatusFilter = 'All';
  final statusFilters = ['All', 'Present', 'Absent', 'Late'];
  static const int exitBufferMinutes = 15;
  // --- SHIFT CACHE (id -> WeeklyShiftModel) ---
  final Map<String, WeeklyShiftModel> _shiftsById = {};

  // default fallback shift id when employee.shiftId is missing
  static const String _defaultFallbackShiftId =
      '8f1074fd-6628-433a-80fd-370415333925';
  OverlayEntry? _tooltipOverlay;
  List<EmployeeAttendanceData> allAttendanceData = [];

  @override
  void initState() {
    super.initState();
    _loadAttendanceLogs();
    _loadAllShifts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllShifts() async {
    try {
      final shifts = await ShiftHelper.getAllShifts(companyId: 'A');
      for (var s in shifts) {
        _shiftsById[s.id] = s;
      }
      setState(() {}); // update UI so late detection can use shifts
    } catch (e) {
      debugPrint("Failed to load shifts: $e");
    }
  }

  Future<void> _loadAttendanceLogs() async {
    _logsPager = AttendanceLogHelper.getStreamData(
      "C",
      limit: 1000,
    );
    await _logsPager!.start();
  }

  // Build employee attendance data combining logs + shift info
  List<EmployeeAttendanceData> _buildAttendanceData(
      List<AttendanceLog> allLogs) {
    final selectedDateStart = DateTime.utc(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final selectedDateEnd = selectedDateStart.add(const Duration(days: 1));

    bool isSameDay(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    final logsForDate = allLogs.where((log) {
      return isSameDay(log.timestamp, _selectedDate);
    }).toList();

    final Map<String, List<AttendanceLog>> employeeLogsMap = {};
    for (var log in logsForDate) {
      employeeLogsMap.putIfAbsent(log.employeeId, () => []);
      employeeLogsMap[log.employeeId]!.add(log);
    }

    return widget.employees.map((employee) {
      final employeeLogs = employeeLogsMap[employee.id] ?? [];
      return _createEmployeeAttendanceData(employee, employeeLogs);
    }).toList();
  }

// Replace your _createEmployeeAttendanceData method with this corrected version

  EmployeeAttendanceData _createEmployeeAttendanceData(
    Employee employee,
    List<AttendanceLog> logs,
  ) {
    final weekDay = WeekDay.values[(_selectedDate.weekday - 1) % 7];

    if (logs.isEmpty) {
      final now = ServerTimeService.instance.currentServerTime;
      final isToday = _selectedDate.year == now.year &&
          _selectedDate.month == now.month &&
          _selectedDate.day == now.day;
      final isPast =
          _selectedDate.isBefore(DateTime(now.year, now.month, now.day));

      final status = isPast ? 'Absent' : (isToday ? 'Not checked in yet' : '-');

      return EmployeeAttendanceData(
        employee: employee,
        log: null,
        status: status,
        checkInTime: null,
        checkOutTime: null,
        totalTime: null,
        isLate: false,
      );
    }

    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final checkInLog =
        logs.firstWhereOrNull((log) => log.eventType == 'check-in');
    final checkOutLog =
        logs.lastWhereOrNull((log) => log.eventType == 'check-out');

    String? totalTime;
    if (checkInLog != null && checkOutLog != null) {
      final duration = checkOutLog.timestamp.difference(checkInLog.timestamp);
      totalTime = '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }

    final status = checkOutLog != null
        ? 'Checked Out'
        : (checkInLog != null ? 'Present' : 'On Break');

    // CORRECTED LATE DETECTION
    bool isLate = false;
    if (checkInLog != null) {
      final shiftId = employee.shiftId?.isNotEmpty == true
          ? employee.shiftId!
          : _defaultFallbackShiftId;

      final shift = _shiftsById[shiftId];
      if (shift != null) {
        final daySchedule = shift.weekSchedule[weekDay];
        if (daySchedule != null &&
            daySchedule.shifts.isNotEmpty &&
            !(daySchedule.isOff ?? false)) {
          final firstShift = daySchedule.shifts.first;

          isLate = _isLate(
            checkInTime: checkInLog.timestamp, // IST DateTime
            shiftStartTime: firstShift.startTime, // CustomTimeOfDay
            bufferTimeMinutes: shift.bufferTimeMinutes,
            date: _selectedDate,
          );
        }
      }
    }
// -------------------------------------------------------------
//                ✔ PARTIAL SHIFT DETECTION
// -------------------------------------------------------------
    bool isPartialShift = false;

    if (checkInLog != null && checkOutLog != null) {
      final shiftId = employee.shiftId?.isNotEmpty == true
          ? employee.shiftId!
          : _defaultFallbackShiftId;

      final shift = _shiftsById[shiftId];

      if (shift != null) {
        final daySchedule = shift.weekSchedule[weekDay];

        if (daySchedule != null && daySchedule.shifts.isNotEmpty) {
          final s = daySchedule.shifts.first;

          // Shift start datetime (IST)
          final shiftStartIST = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            s.startTime.hour,
            s.startTime.minute,
          );

          // Full shift duration in minutes
          final fullShiftMinutes = (s.durationInHours * 60).round();

          // Allowed checkout = full duration - buffer
          final allowedCheckoutIST = shiftStartIST.add(
            Duration(
              minutes: fullShiftMinutes - exitBufferMinutes,
            ),
          );

          final checkoutIST = checkOutLog.timestamp.toLocal();

          if (checkoutIST.isBefore(allowedCheckoutIST)) {
            isPartialShift = true;
          }

          debugPrint("=== PARTIAL SHIFT CHECK ===");
          debugPrint("Shift Start: $shiftStartIST");
          debugPrint("Full Minutes: $fullShiftMinutes");
          debugPrint("Allowed Checkout: $allowedCheckoutIST");
          debugPrint("Actual Checkout: $checkoutIST");
          debugPrint("Partial: $isPartialShift");
        }
      }
    }

    return EmployeeAttendanceData(
      employee: employee,
      log: checkInLog ?? logs.first,
      status: status,
      checkInTime: checkInLog != null
          ? DateFormat('h:mm a').format(checkInLog.timestamp)
          : null,
      checkOutTime: checkOutLog != null
          ? DateFormat('h:mm a').format(checkOutLog.timestamp)
          : null,
      totalTime: totalTime,
      isLate: isLate, isPartialShift: isPartialShift, // NEW
    );
  }

  bool _isLate({
    required DateTime checkInTime, // Now truly in IST (local)
    required CustomTimeOfDay shiftStartTime,
    required String bufferTimeMinutes,
    required DateTime date,
  }) {
    // Create shift start time as local DateTime (IST)
    final shiftStartIST = DateTime(
      date.year,
      date.month,
      date.day,
      shiftStartTime.hour,
      shiftStartTime.minute,
      0,
      0,
    );

    // Parse buffer time
    final buffer = int.tryParse(bufferTimeMinutes.trim()) ?? 0;

    // Calculate allowed check-in time
    final allowedCheckInTime = shiftStartIST.add(Duration(minutes: buffer));

    // Debug print
    debugPrint('==== Late Detection Debug ====');
    debugPrint(
        'Employee Check-in (IST): $checkInTime (isUtc: ${checkInTime.isUtc})');
    debugPrint('Shift Start (IST): $shiftStartIST');
    debugPrint('Buffer Minutes: $buffer');
    debugPrint('Allowed Check-in (IST): $allowedCheckInTime');

    // Extract just the time components for comparison
    final checkInTimeOnly = DateTime(
      checkInTime.year,
      checkInTime.month,
      checkInTime.day,
      checkInTime.hour,
      checkInTime.minute,
      checkInTime.second,
    );

    debugPrint('Check-in time only: $checkInTimeOnly');
    debugPrint('Is Late: ${checkInTimeOnly.isAfter(allowedCheckInTime)}');
    debugPrint('==============================');

    // Compare the times
    return checkInTimeOnly.isAfter(allowedCheckInTime);
  }

  int _getPartialShiftEmployees(List<EmployeeAttendanceData> data) =>
      data.where((d) => d.isPartialShift).length;

  // Apply search + status filters
  List<EmployeeAttendanceData> _applyFilters(
      List<EmployeeAttendanceData> data) {
    final query = _searchController.text.toLowerCase();

    return data.where((item) {
      final matchesSearch = item.employee.name.toLowerCase().contains(query) ||
          item.employee.empID.toLowerCase().contains(query);

      final matchesStatus = selectedStatusFilter == 'All'
          ? true
          : (selectedStatusFilter == 'Late'
              ? item.isLate == true
              : item.status.toLowerCase() ==
                  selectedStatusFilter.toLowerCase());

      return matchesSearch && matchesStatus;
    }).toList();
  }

  List<WeeklyAttendanceData> _calculateWeeklyAttendance(
      List<AttendanceLog> allLogs) {
    final now = ServerTimeService.instance.currentServerTime;
    final weeklyData = <WeeklyAttendanceData>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayLogs = allLogs.where((log) {
        return !log.timestamp.isBefore(dayStart) &&
            log.timestamp.isBefore(dayEnd) &&
            log.eventType == 'check-in';
      }).toList();

      final presentEmployeeIds = <String>{};
      for (var log in dayLogs) {
        presentEmployeeIds.add(log.employeeId);
      }

      final presentCount = presentEmployeeIds.length;
      final absentCount = widget.employees.length - presentCount;

      weeklyData.add(WeeklyAttendanceData(
        day: DateFormat('EEE').format(date),
        present: presentCount,
        absent: absentCount,
      ));
    }

    return weeklyData;
  }

  /// Build attendance for ANY date range, not just selected date
  List<EmployeeAttendanceData> buildAttendanceForDateRange(
    List<Employee> employees,
    List<AttendanceLog> allLogs,
    DateTime start,
    DateTime end,
  ) {
    List<EmployeeAttendanceData> results = [];

    // Expand date range day-by-day
    for (DateTime date = start;
        !date.isAfter(end);
        date = date.add(const Duration(days: 1))) {
      final dailyLogs = allLogs.where((log) {
        return log.timestamp.year == date.year &&
            log.timestamp.month == date.month &&
            log.timestamp.day == date.day;
      }).toList();

      // Map logs by employee
      final Map<String, List<AttendanceLog>> empMap = {};
      for (var log in dailyLogs) {
        empMap.putIfAbsent(log.employeeId, () => []);
        empMap[log.employeeId]!.add(log);
      }

      // Build data for each employee for this date
      for (final emp in employees) {
        final logs = empMap[emp.id] ?? [];
        final data = _createEmployeeAttendanceDataForDate(emp, logs, date);
        results.add(data);
      }
    }

    return results;
  }

  EmployeeAttendanceData _createEmployeeAttendanceDataForDate(
    Employee employee,
    List<AttendanceLog> logs,
    DateTime date,
  ) {
    final weekDay = WeekDay.values[(date.weekday - 1) % 7];

    if (logs.isEmpty) {
      return EmployeeAttendanceData(
        employee: employee,
        log: null,
        status: 'Absent',
        checkInTime: null,
        checkOutTime: null,
        totalTime: null,
        isLate: false,
      );
    }

    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final checkInLog =
        logs.firstWhereOrNull((log) => log.eventType == 'check-in');
    final checkOutLog =
        logs.lastWhereOrNull((log) => log.eventType == 'check-out');

    final status = checkOutLog != null
        ? 'Checked Out'
        : (checkInLog != null ? 'Present' : 'On Break');

    String? totalTime;
    if (checkInLog != null && checkOutLog != null) {
      final duration = checkOutLog.timestamp.difference(checkInLog.timestamp);
      totalTime = '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }

    bool isLate = false;
    if (checkInLog != null) {
      final shiftId = employee.shiftId ?? _defaultFallbackShiftId;
      final shift = _shiftsById[shiftId];

      if (shift != null) {
        final daySchedule = shift.weekSchedule[weekDay];
        if (daySchedule != null && daySchedule.shifts.isNotEmpty) {
          final s = daySchedule.shifts.first;

          isLate = _isLate(
            checkInTime: checkInLog.timestamp,
            shiftStartTime: s.startTime,
            bufferTimeMinutes: shift.bufferTimeMinutes,
            date: date,
          );
        }
      }
    }

    return EmployeeAttendanceData(
      employee: employee,
      log: checkInLog ?? logs.first,
      status: status,
      checkInTime: checkInLog != null
          ? DateFormat('h:mm a').format(checkInLog.timestamp)
          : null,
      checkOutTime: checkOutLog != null
          ? DateFormat('h:mm a').format(checkOutLog.timestamp)
          : null,
      totalTime: totalTime,
      isLate: isLate,
    );
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
  }

  int _getTotalEmployees(List<EmployeeAttendanceData> data) =>
      widget.employees.length;
  int _getPresentEmployees(List<EmployeeAttendanceData> data) => data
      .where((d) =>
          d.status.toLowerCase() == 'present' ||
          d.status.toLowerCase() == 'checked out')
      .length;
  int _getAbsentEmployees(List<EmployeeAttendanceData> data) =>
      data.where((d) => d.status.toLowerCase() == 'absent').length;
  int _getOnBreakEmployees(List<EmployeeAttendanceData> data) =>
      data.where((d) => d.status.toLowerCase() == 'on break').length;

  @override
  Widget build(BuildContext context) {
    if (_logsPager == null) {
      return Container(
        color: const Color(0xFF14151A),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      color: const Color(0xFF14151A),
      padding: const EdgeInsets.all(8),
      child: StreamBuilder<List<AttendanceLog>>(
        stream: _logsPager!.stream.convertStream(
          converter: (val) => val.expand((e) => e.items).toList(),
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allLogs = snapshot.data!;
          final attendanceData = _buildAttendanceData(allLogs);
          final filteredData = _applyFilters(attendanceData);

// ADD THIS LINE:
          allAttendanceData = attendanceData;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildStatsGrid(attendanceData, allLogs),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        "Overall Attendance",
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showDateRangePicker(context, allLogs),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text("Export by Date Range"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E7CE2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTodaysAttendanceSection(filteredData),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDateRangePicker(
      BuildContext context, List<AttendanceLog> allLogs) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      final fullData = buildAttendanceForDateRange(
        widget.employees,
        allLogs,
        picked.start,
        picked.end,
      );

      if (fullData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No attendance data in selected range")),
        );
        return;
      }

      attendanceDownload.exportToExcelWithDateRange(
        fullData,
        context,
        picked.start,
        picked.end,
      );
    }
  }

  List<String> _getEmployeeNamesByStatus(
      List<EmployeeAttendanceData> data, String status) {
    switch (status.toLowerCase()) {
      case 'late':
        return data.where((d) => d.isLate).map((d) => d.employee.name).toList();

      case 'present':
        return data
            .where((d) =>
                d.status.toLowerCase() == 'present' ||
                d.status.toLowerCase() == 'checked out')
            .map((d) => d.employee.name)
            .toList();

      case 'absent':
        return data
            .where((d) => d.status.toLowerCase() == 'absent')
            .map((d) => d.employee.name)
            .toList();

      case 'on break':
        return data
            .where((d) => d.status.toLowerCase() == 'on break')
            .map((d) => d.employee.name)
            .toList();

      case 'partial shift':
        return data
            .where((d) => d.isPartialShift == true)
            .map((d) => d.employee.name)
            .toList();

      default:
        return [];
    }
  }

  Widget _statCardWithTooltip({
    required String title,
    required String count,
    required IconData icon,
    required List<String> names,
  }) {
    final key = GlobalKey();

    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final renderBox = key.currentContext!.findRenderObject() as RenderBox;
        final offset = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        final rect = Rect.fromLTWH(
          offset.dx,
          offset.dy,
          size.width,
          size.height,
        );

        _showTooltip(
          context,
          rect,
          title: title,
          names: names,
        );
      },
      child: StatCard(
        title: title,
        count: count,
        icon: icon,
      ),
    );
  }

  Widget _buildStatsGrid(
      List<EmployeeAttendanceData> data, List<AttendanceLog> allLogs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===================== LEFT COLUMN =========================
        Column(
          children: [
            _statCardWithTooltip(
              title: "Total",
              count: _getTotalEmployees(data).toString(),
              icon: Icons.people_outline,
              names: data.map((d) => d.employee.name).toList(),
            ),
            const SizedBox(height: 16),
            _statCardWithTooltip(
              title: "Present",
              count: _getPresentEmployees(data).toString(),
              icon: Icons.check_circle_outline,
              names: _getEmployeeNamesByStatus(data, "present"),
            ),
            const SizedBox(height: 16),
            _statCardWithTooltip(
              title: "Late",
              count: data.where((d) => d.isLate).length.toString(),
              icon: Icons.warning_amber_rounded,
              names: _getEmployeeNamesByStatus(data, "late"),
            ),
          ],
        ),

        const SizedBox(width: 20),

        // ===================== RIGHT COLUMN =========================
        Column(
          children: [
            _statCardWithTooltip(
              title: "On Break",
              count: _getOnBreakEmployees(data).toString(),
              icon: Icons.event_busy_outlined,
              names: _getEmployeeNamesByStatus(data, "on break"),
            ),
            const SizedBox(height: 16),
            _statCardWithTooltip(
              title: "Absent",
              count: _getAbsentEmployees(data).toString(),
              icon: Icons.person_off_outlined,
              names: _getEmployeeNamesByStatus(data, "absent"),
            ),
            const SizedBox(height: 16),
            _statCardWithTooltip(
              title: "Partial Shift",
              count: _getPartialShiftEmployees(data).toString(),
              icon: Icons.access_time,
              names: _getEmployeeNamesByStatus(data, "partial shift"),
            ),
          ],
        ),

        const SizedBox(width: 20),

        // ===================== CHART COLUMN =========================
        Expanded(
          flex: 1,
          child: GradientContainer(
            height: 360,
            padding: const EdgeInsets.all(20),
            child: _buildChart(allLogs),
          ),
        ),
      ],
    );
  }

  void _showTooltip(
    BuildContext context,
    Rect targetPos, {
    required String title,
    required List<String> names,
  }) {
    _hideTooltip(); // remove previous overlay

    final overlay = Overlay.of(context);
    final screen = MediaQuery.of(context).size;

    const maxHeight = 260.0;
    final width = screen.width < 420 ? screen.width * 0.75 : 280.0;

    double left = targetPos.left + 50;
    double top = targetPos.top - 50;

    // If tooltip goes out of right side → show on left
    if (left + width > screen.width - 12) {
      left = targetPos.left - width - 12;
    }

    // Left screen clamp
    if (left < 12) left = 12;

    // Adjust if bottom is overflowing
    final overflow = (top + maxHeight + 30) - screen.height;
    if (overflow > 0) {
      top -= overflow + 20;
    }
    if (top < 12) top = 12;

    _tooltipOverlay = OverlayEntry(
      builder: (_) {
        return Stack(
          children: [
            // Tap outside to close
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideTooltip,
                child: Container(color: Colors.transparent),
              ),
            ),

            // Tooltip bubble
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: width,
                  constraints: const BoxConstraints(maxHeight: maxHeight),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1D23),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3A3B43)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      names.isEmpty
                          ? const Text("No employees",
                              style: TextStyle(
                                  color: Color(0xFF8B8D97), fontSize: 14))
                          : Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: names.map((name) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Row(
                                        children: [
                                          const CircleAvatar(
                                            radius: 10,
                                            backgroundColor: Color(0xFF5E7CE2),
                                            child: Icon(Icons.person,
                                                size: 12, color: Colors.white),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            )
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_tooltipOverlay!);
  }

  void _hideTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  Widget _buildChart(List<AttendanceLog> allLogs) {
    final weeklyData = _calculateWeeklyAttendance(allLogs);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Weekly Attendance',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        Expanded(
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            primaryXAxis: const CategoryAxis(
                majorGridLines: MajorGridLines(width: 0),
                axisLine: AxisLine(width: 0),
                labelStyle: TextStyle(color: Color(0xFF8B8D97), fontSize: 12)),
            primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(
                    width: 0.5,
                    color: const Color(0xFF3A3B43).withOpacity(0.3)),
                axisLine: const AxisLine(width: 0),
                labelStyle:
                    const TextStyle(color: Color(0xFF8B8D97), fontSize: 12)),
            legend: const Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                textStyle: TextStyle(color: Color(0xFF8B8D97), fontSize: 12)),
            tooltipBehavior: TooltipBehavior(
                enable: true,
                color: const Color(0xFF2C2D35),
                textStyle: const TextStyle(color: Colors.white)),
            series: <CartesianSeries>[
              StackedColumnSeries<WeeklyAttendanceData, String>(
                dataSource: weeklyData,
                xValueMapper: (d, _) => d.day,
                yValueMapper: (d, _) => d.present,
                name: 'Present',
                color: const Color(0xFF454890),
              ),
              StackedColumnSeries<WeeklyAttendanceData, String>(
                  dataSource: weeklyData,
                  xValueMapper: (d, _) => d.day,
                  yValueMapper: (d, _) => d.absent,
                  name: 'Absent',
                  color: const Color(0xFFFF3B30).withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSwitcher() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ← Previous Day
        InkWell(
          onTap: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
            });
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2C2D35),
            ),
            child: const Icon(Icons.arrow_left, color: Colors.white, size: 26),
          ),
        ),

        const SizedBox(width: 20),

        // 📅 Center Date (Tap to Pick Date)
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: ServerTimeService.instance.currentServerTime,
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFF5E7CE2),
                      onPrimary: Colors.white,
                      surface: Color(0xFF2C2D35),
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Text(
            DateFormat('d MMM yyyy').format(_selectedDate),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 20),

        // → Next Day
        InkWell(
          onTap: () {
            setState(() {
              final today = ServerTimeService.instance.currentServerTime;
              final onlyToday = DateTime(today.year, today.month, today.day);

              if (_selectedDate.isBefore(onlyToday)) {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              }
            });
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2C2D35),
            ),
            child: const Icon(Icons.arrow_right, color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysAttendanceSection(
      List<EmployeeAttendanceData> filteredData) {
    return GradientContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateSwitcher(), // ⬅ NEW DATE SWITCHER
              const SizedBox(height: 24),
              // SEARCH BOX
              Container(
                width: 400,
                height: 40,
                padding: const EdgeInsets.only(left: 18, right: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppDefault.bordercolor,
                    width: 0.57,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (query) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFF8B8D97),
                      fontWeight: FontWeight.w300,
                      fontSize: 15,
                    ),
                    suffixIcon: const Icon(
                      Icons.search_outlined,
                      color: Color(0xFF8B8D97),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(width: 16),
              _buildStatusFilters(),
            ],
          ),
          const SizedBox(height: 24),
          AttendanceTable(attendanceData: filteredData),
        ],
      ),
    );
  }

  Widget _buildChangeDateButton() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: ServerTimeService.instance.currentServerTime,
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF5E7CE2),
                    onPrimary: Colors.white,
                    surface: Color(0xFF2C2D35),
                    onSurface: Colors.white),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) _onDateChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: const Color(0xFF2C2D35),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3A3B43), width: 1)),
        child: const Row(children: [
          Icon(Icons.calendar_today, color: Color(0xFF8B8D97), size: 16),
          SizedBox(width: 8),
          Text('Change Date',
              style: TextStyle(color: Color(0xFF8B8D97), fontSize: 14))
        ]),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        decoration: BoxDecoration(
          // color: const Color(0xFF2C2D35),
          borderRadius: BorderRadius.circular(8),
          // border: Border.all(color: const Color(0xFF3A3B43), width: 1),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: statusFilters.map((filter) {
                final bool isSelected = selectedStatusFilter == filter;
                return GestureDetector(
                  onTap: () => setState(() => selectedStatusFilter = filter),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF5E7CE2)
                            : const Color(0xFFFFFFFF).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(filter,
                        style: GoogleFonts.poppins(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF9D9D9D),
                            fontSize: 13,
                            fontWeight: FontWeight.w400)),
                  ),
                );
              }).toList()),
        ),
      ),
    );
  }
}

class WeeklyAttendanceData {
  final String day;
  final int present;
  final int absent;

  WeeklyAttendanceData(
      {required this.day, required this.present, required this.absent});
}

extension IterableX<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  E? lastWhereOrNull(bool Function(E) test) {
    E? result;
    for (final element in this) {
      if (test(element)) result = element;
    }
    return result;
  }
}
