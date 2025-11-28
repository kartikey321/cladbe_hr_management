import 'package:cladbe_hr_management/src/Helpers/attendance_log_helper.dart';
import 'package:cladbe_hr_management/src/models/EmployeeAttendanceData.dart';
import 'package:flutter/material.dart';
import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:cladbe_shared/sql_client.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'widgets/gradient_container.dart';
import 'widgets/stat_card.dart';
import 'widgets/attendance_table.dart';

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
  DateTime _selectedDate = DateTime.now();
  LivePager<AttendanceLog>? _logsPager;

  @override
  void initState() {
    super.initState();
    _loadAttendanceLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    // _logsPager?.stop();
    super.dispose();
  }

  Future<void> _loadAttendanceLogs() async {
    _logsPager = AttendanceLogHelper.getStreamData(
      'C',
      limit: 1000,
    );
    await _logsPager!.start();
  }

  List<EmployeeAttendanceData> _buildAttendanceData(
      List<AttendanceLog> allLogs) {
    final selectedDateStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final selectedDateEnd = selectedDateStart.add(const Duration(days: 1));

    final logsForDate = allLogs.where((log) {
      return log.timestamp.isAfter(selectedDateStart) &&
          log.timestamp.isBefore(selectedDateEnd);
    }).toList();

    final Map<String, List<AttendanceLog>> employeeLogsMap = {};
    for (var log in logsForDate) {
      if (!employeeLogsMap.containsKey(log.employeeId)) {
        employeeLogsMap[log.employeeId] = [];
      }
      employeeLogsMap[log.employeeId]!.add(log);
    }

    return widget.employees.map((employee) {
      final employeeLogs = employeeLogsMap[employee.id] ?? [];
      return _createEmployeeAttendanceData(employee, employeeLogs);
    }).toList();
  }

  EmployeeAttendanceData _createEmployeeAttendanceData(
    Employee employee,
    List<AttendanceLog> logs,
  ) {
    if (logs.isEmpty) {
      final now = DateTime.now();
      final isToday = _selectedDate.year == now.year &&
          _selectedDate.month == now.month &&
          _selectedDate.day == now.day;
      final isPast = _selectedDate.isBefore(
        DateTime(now.year, now.month, now.day),
      );

      return EmployeeAttendanceData(
        employee: employee,
        log: null,
        status: isPast ? 'Absent' : (isToday ? 'Not checked in yet' : '-'),
        checkInTime: null,
        checkOutTime: null,
        totalTime: null,
      );
    }

    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    AttendanceLog? checkInLog;
    AttendanceLog? checkOutLog;

    for (var log in logs) {
      if (log.eventType == 'check-in' && checkInLog == null) {
        checkInLog = log;
      }
      if (log.eventType == 'check-out') {
        checkOutLog = log;
      }
    }

    String? totalTime;
    if (checkInLog != null && checkOutLog != null) {
      final duration = checkOutLog.timestamp.difference(checkInLog.timestamp);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      totalTime = '${hours}h ${minutes}m';
    }

    String status;
    if (checkOutLog != null) {
      status = 'Checked Out';
    } else if (checkInLog != null) {
      status = 'Present';
    } else {
      status = 'On Break';
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
    );
  }

  List<EmployeeAttendanceData> _filterEmployees(
    List<EmployeeAttendanceData> data,
    String query,
  ) {
    if (query.isEmpty) return data;
    return data
        .where((d) =>
            d.employee.name.toLowerCase().contains(query.toLowerCase()) ||
            d.employee.empID.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<WeeklyAttendanceData> _calculateWeeklyAttendance(
      List<AttendanceLog> allLogs) {
    final now = DateTime.now();
    final weeklyData = <WeeklyAttendanceData>[];

    // Get last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      // Get logs for this day
      final dayLogs = allLogs.where((log) {
        return log.timestamp.isAfter(dayStart) &&
            log.timestamp.isBefore(dayEnd) &&
            log.eventType == 'check-in';
      }).toList();

      // Count unique employees who checked in (present)
      final presentEmployeeIds = <String>{};
      for (var log in dayLogs) {
        presentEmployeeIds.add(log.employeeId);
      }

      final presentCount = presentEmployeeIds.length;
      final absentCount = widget.employees.length - presentCount;

      weeklyData.add(WeeklyAttendanceData(
        day: DateFormat('EEE').format(date), // Mon, Tue, Wed, etc.
        present: presentCount,
        absent: absentCount,
      ));
    }

    return weeklyData;
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
  }

  int _getTotalEmployees(List<EmployeeAttendanceData> data) =>
      widget.employees.length;
  int _getPresentEmployees(List<EmployeeAttendanceData> data) => data
      .where((d) => d.status == 'Present' || d.status == 'Checked Out')
      .length;
  int _getAbsentEmployees(List<EmployeeAttendanceData> data) =>
      data.where((d) => d.status == 'Absent').length;
  int _getOnBreakEmployees(List<EmployeeAttendanceData> data) =>
      data.where((d) => d.status == 'On Break').length;

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
          final filteredData = _filterEmployees(
            attendanceData,
            _searchController.text,
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(attendanceData, allLogs),
                const SizedBox(height: 24),
                _buildTodaysAttendanceSection(filteredData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(
      List<EmployeeAttendanceData> data, List<AttendanceLog> allLogs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 19,
      children: [
        Expanded(
          flex: 0,
          child: Column(
            children: [
              StatCard(
                title: 'Total',
                count: _getTotalEmployees(data).toString(),
                icon: Icons.people_outline,
              ),
              const SizedBox(height: 16),
              StatCard(
                title: 'Absent',
                count: _getAbsentEmployees(data).toString(),
                icon: Icons.person_off_outlined,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 0,
          child: Column(
            children: [
              StatCard(
                title: 'Present',
                count: _getPresentEmployees(data).toString(),
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 16),
              StatCard(
                title: 'On Break',
                count: _getOnBreakEmployees(data).toString(),
                icon: Icons.event_busy_outlined,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: GradientContainer(
            height: 360.9,
            padding: const EdgeInsets.all(20),
            child: _buildChart(allLogs),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<AttendanceLog> allLogs) {
    final weeklyData = _calculateWeeklyAttendance(allLogs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Attendance',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            primaryXAxis: const CategoryAxis(
              majorGridLines: MajorGridLines(width: 0),
              axisLine: AxisLine(width: 0),
              labelStyle: TextStyle(
                color: Color(0xFF8B8D97),
                fontSize: 12,
              ),
            ),
            primaryYAxis: NumericAxis(
              majorGridLines: MajorGridLines(
                width: 0.5,
                color: const Color(0xFF3A3B43).withValues(alpha: 0.3),
              ),
              axisLine: const AxisLine(width: 0),
              labelStyle: const TextStyle(
                color: Color(0xFF8B8D97),
                fontSize: 12,
              ),
            ),
            legend: const Legend(
              isVisible: true,
              position: LegendPosition.bottom,
              textStyle: TextStyle(
                color: Color(0xFF8B8D97),
                fontSize: 12,
              ),
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              color: const Color(0xFF2C2D35),
              textStyle: const TextStyle(color: Colors.white),
            ),
            series: <CartesianSeries>[
              StackedColumnSeries<WeeklyAttendanceData, String>(
                dataSource: weeklyData,
                xValueMapper: (WeeklyAttendanceData data, _) => data.day,
                yValueMapper: (WeeklyAttendanceData data, _) => data.present,
                name: 'Present',
                color: const Color(0xFF5E7CE2),
                // borderRadius: const BorderRadius.only(
                //   topLeft: Radius.circular(4),
                //   topRight: Radius.circular(4),
                // ),
              ),
              StackedColumnSeries<WeeklyAttendanceData, String>(
                dataSource: weeklyData,
                xValueMapper: (WeeklyAttendanceData data, _) => data.day,
                yValueMapper: (WeeklyAttendanceData data, _) => data.absent,
                name: 'Absent',
                color: const Color(0xFFFF6B6B),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
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
              Row(
                children: [
                  Text(
                    DateFormat('MMMM dd, yyyy').format(_selectedDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
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
                      if (picked != null) {
                        _onDateChanged(picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2D35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF3A3B43),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Color(0xFF8B8D97),
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Change Date',
                            style: TextStyle(
                              color: Color(0xFF8B8D97),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                width: 300,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2D35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF3A3B43),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (query) => setState(() {}),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(
                      color: Color(0xFF8B8D97),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color(0xFF8B8D97),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AttendanceTable(attendanceData: filteredData),
        ],
      ),
    );
  }
}

class WeeklyAttendanceData {
  final String day;
  final int present;
  final int absent;

  WeeklyAttendanceData({
    required this.day,
    required this.present,
    required this.absent,
  });
}
