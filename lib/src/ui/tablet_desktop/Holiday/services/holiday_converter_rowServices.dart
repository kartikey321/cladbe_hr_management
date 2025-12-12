import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';

class LeaveRow {
  MultiSelectController leaveTypeController = MultiSelectController();
  LeaveType? selectedLeaveType;
  String? customLeaveName; // <── store typed name

  /// Right side suggestion field
  TextEditingController leaveNameController = TextEditingController();
  LeaveName? selectedLeaveName;

  bool transferable = false;

  TextEditingController daysController = TextEditingController();
}

class OccasionRow {
  TextEditingController nameController = TextEditingController();

  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
}

class HolidayConverter {
  static Map<String, dynamic>? validate({
    required String name,
    required String description,
    required List<LeaveRow> leaveRows,
    required List<OccasionRow> occasionRows,
  }) {
    List<String> errors = [];

    // -------------------------------
    // 🔹 Name Required
    // -------------------------------
    if (name.trim().isEmpty) {
      errors.add("Holiday name is required.");
    }

    // -------------------------------------
    // 🔹 Validate Leave Rows
    // -------------------------------------
    for (int i = 0; i < leaveRows.length; i++) {
      var row = leaveRows[i];

      if (row.selectedLeaveType == null) {
        errors.add("Leave row ${i + 1}: Leave type is required.");
      }

      if (row.selectedLeaveName == null) {
        errors.add("Leave row ${i + 1}: Leave name is required.");
      }

      if (row.daysController.text.isEmpty) {
        errors.add("Leave row ${i + 1}: Amount of days is required.");
      } else {
        int? days = int.tryParse(row.daysController.text);
        if (days == null || days <= 0) {
          errors.add("Leave row ${i + 1}: Days must be more than zero.");
        }
      }
    }

    // -------------------------------------
    // 🔹 Validate Occasion Rows
    // -------------------------------------
    Set<String> occNames = {};
    for (int i = 0; i < occasionRows.length; i++) {
      var row = occasionRows[i];

      if (row.nameController.text.trim().isEmpty) {
        errors.add("Occasion row ${i + 1}: Occasion name is required.");
      }

      // Duplicate name
      if (occNames.contains(row.nameController.text.trim().toLowerCase())) {
        errors.add("Occasion row ${i + 1}: Duplicate occasion name.");
      } else {
        occNames.add(row.nameController.text.trim().toLowerCase());
      }

      if (row.startDate == null) {
        errors.add("Occasion row ${i + 1}: Start date is required.");
      }
      if (row.endDate == null) {
        errors.add("Occasion row ${i + 1}: End date is required.");
      }

      if (row.startDate != null &&
          row.endDate != null &&
          row.endDate!.isBefore(row.startDate!)) {
        errors.add(
            "Occasion row ${i + 1}: End date cannot be before the start date.");
      }
    }

    // --------------------------------------------
    // 🔥 OVERLAP VALIDATION BETWEEN OCCASION DATES
    // --------------------------------------------
    for (int i = 0; i < occasionRows.length; i++) {
      for (int j = i + 1; j < occasionRows.length; j++) {
        var A = occasionRows[i];
        var B = occasionRows[j];

        if (A.startDate != null &&
            A.endDate != null &&
            B.startDate != null &&
            B.endDate != null) {
          bool overlaps = A.startDate!.isBefore(B.endDate!) &&
              B.startDate!.isBefore(A.endDate!);

          if (overlaps) {
            errors.add(
                "Occasions '${A.nameController.text}' and '${B.nameController.text}' overlap.");
          }
        }
      }
    }

    if (errors.isNotEmpty) {
      return {"success": false, "errors": errors};
    }

    return {"success": true};
  }

  // --------------------------------------------------------------------------
  // FINAL CONVERSION (only called if validate() returns OK)
  // --------------------------------------------------------------------------
  static HolidayModel convertToModel({
    required String name,
    required String description,
    required List<LeaveRow> leaveRows,
    required List<OccasionRow> occasionRows,
    String? existingId,
  }) {
    final id = existingId ?? generateUniqueId();

    final leaves = <LeaveModel>[];
    final occasions = <OccasionModel>[];

    for (var row in leaveRows) {
      if (row.selectedLeaveType == null ||
          row.selectedLeaveName == null ||
          row.daysController.text.isEmpty) continue;

      leaves.add(
        LeaveModel(
          type: row.selectedLeaveType!,
          leaveName: row.selectedLeaveName == LeaveName.custom
              ? (row.customLeaveName?.trim().isNotEmpty == true
                  ? row.customLeaveName!.trim()
                  : "Custom Leave")
              : row.selectedLeaveName!.displayName,
          transferable: row.transferable,
          amountOfDays: int.tryParse(row.daysController.text) ?? 0,
        ),
      );
    }

    for (var row in occasionRows) {
      if (row.nameController.text.isEmpty ||
          row.startDate == null ||
          row.endDate == null) continue;

      occasions.add(
        OccasionModel(
          name: row.nameController.text.trim(),
          startDate: row.startDate!,
          endDate: row.endDate!,
        ),
      );
    }

    int totalDays = 0;
    for (var o in occasions) {
      totalDays += o.endDate.difference(o.startDate).inDays + 1;
    }

    return HolidayModel(
      id: id,
      name: name.trim(),
      description: description.trim(),
      leaves: leaves,
      occasions: occasions,
      totalOccassionsHolidays: totalDays.toString(),
      createdAt: ServerTimeService.instance.currentServerTime,
      updatedAt: ServerTimeService.instance.currentServerTime,
    );
  }
}
