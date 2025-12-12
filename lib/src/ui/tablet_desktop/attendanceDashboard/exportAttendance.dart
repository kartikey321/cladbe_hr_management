import 'dart:typed_data';
import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class attendanceDownload {
  static Future<void> exportToExcelWithDateRange(
    List<EmployeeAttendanceData> data,
    BuildContext context,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final excel = Excel.createExcel();
      final summarySheet = excel['Summary'];
      final detailSheet = excel['Details'];

      // ====================== COLORS =======================
      CellStyle stylePresent =
          CellStyle(backgroundColorHex: "#34C759", fontColorHex: "#FFFFFF");
      CellStyle styleAbsent =
          CellStyle(backgroundColorHex: "#FF3B30", fontColorHex: "#FFFFFF");
      CellStyle styleLate =
          CellStyle(backgroundColorHex: "#FF9500", fontColorHex: "#FFFFFF");
      CellStyle styleBreak =
          CellStyle(backgroundColorHex: "#FFD60A", fontColorHex: "#000000");
      CellStyle stylePartial =
          CellStyle(backgroundColorHex: "#AF52DE", fontColorHex: "#FFFFFF");
      CellStyle styleNeutral =
          CellStyle(backgroundColorHex: "#E5E5EA", fontColorHex: "#000000");

      CellStyle headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: "#1C1C1E",
        fontColorHex: "#FFFFFF",
      );

      // ======================================================
      //  PART 1: SUMMARY SHEET (Date-wise compact table)
      // ======================================================

      // Build list of all dates
      List<DateTime> allDates = [];
      for (DateTime d = startDate;
          !d.isAfter(endDate);
          d = d.add(const Duration(days: 1))) {
        allDates.add(d);
      }

      // ---------- HEADER ----------
      List<String> header = ["EmpID", "Name"];
      header.addAll(allDates.map((d) => DateFormat("dd MMM").format(d)));
      summarySheet.appendRow(header);

      for (int c = 0; c < header.length; c++) {
        summarySheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
            .cellStyle = headerStyle;
      }

      // Group data per employee per date
      final Map<String, Map<String, EmployeeAttendanceData>> grouped = {};

      for (var d in data) {
        String empId = d.employee.empID;
        String dateKey = DateFormat("yyyy-MM-dd")
            .format(d.log?.timestamp.toLocal() ?? DateTime(2000));

        grouped.putIfAbsent(empId, () => {});
        grouped[empId]![dateKey] = d;
      }

      // ---------- ROWS ----------
      int rowIndex = 1;

      for (var empGroup in grouped.entries) {
        final empId = empGroup.key;
        final entries = empGroup.value;

        // Find any record to get name
        String empName = entries.values.first.employee.name;

        List<dynamic> row = [empId, empName];
        summarySheet.appendRow(row);

        int colIndex = 2;

        for (var day in allDates) {
          final key = DateFormat("yyyy-MM-dd").format(day);
          final record = entries[key];

          String value = "-";
          CellStyle style = styleNeutral;

          if (record != null) {
            String status = record.status.toLowerCase();

            if (status == "absent") {
              value = "Absent";
              style = styleAbsent;
            } else if (status == "present" || status == "checked out") {
              value = "Present";
              style = stylePresent;
            } else if (status == "on break") {
              value = "On Break";
              style = styleBreak;
            } else if (record.isPartialShift == true) {
              value = "Partial";
              style = stylePartial;
            } else if (record.isLate) {
              value = "Late";
              style = styleLate;
            }
          }

          final cell = summarySheet.cell(
            CellIndex.indexByColumnRow(
                columnIndex: colIndex, rowIndex: rowIndex),
          );

          cell.value = value;
          cell.cellStyle = style;
          colIndex++;
        }

        rowIndex++;
      }

      // Auto width Emp ID & Name
      summarySheet.setColWidth(0, 20);
      summarySheet.setColWidth(1, 25);

      // ======================================================
      //  PART 2: DETAILED SHEET (Full logs)
      // ======================================================

      final detailHeader = [
        'Employee ID',
        'Name',
        'Date',
        'Check-in',
        'Check-out',
        'Total Hours',
        'Status',
        'Late?'
      ];

      detailSheet.appendRow(detailHeader);

      for (int c = 0; c < detailHeader.length; c++) {
        detailSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
            .cellStyle = headerStyle;
      }

      int dRow = 1;

      for (var d in data) {
        final log = d.log;
        final dateStr =
            log != null ? DateFormat("yyyy-MM-dd").format(log.timestamp) : "-";

        final row = [
          d.employee.empID,
          d.employee.name,
          dateStr,
          d.checkInTime ?? "-",
          d.checkOutTime ?? "-",
          d.totalTime ?? "-",
          d.status,
          d.isLate ? "Yes" : "No",
        ];

        detailSheet.appendRow(row);
        dRow++;
      }

      // ======================================================
      //  SAVE FILE
      // ======================================================

      final bytes = excel.encode();
      if (bytes == null) throw ("Excel creation failed");

      final fileName =
          "Attendance_${DateFormat('ddMMMyy').format(startDate)}-${DateFormat('ddMMMyy').format(endDate)}";

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(bytes),
        ext: "xlsx",
        mimeType: MimeType.microsoftExcel,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Excel exported successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      LoggerService.error("Export failed: $e");
    }
  }
}
