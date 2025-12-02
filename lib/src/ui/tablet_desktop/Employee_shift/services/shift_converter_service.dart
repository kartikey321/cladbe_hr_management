import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';

import '../widget/time_slot_models.dart';

/// Converts UI data into model update maps for WeeklyShiftModel.
class ShiftConverterService {
  /// Converts UI shift/break state into a Map for creating/updating the model
  static Map<String, dynamic>? convertToMap({
    required String shiftName,
    required String description,
    required List<String> weekDays,
    required Map<String, List<ShiftTimeSlot>> dayShifts,
    required Map<String, List<BreakTimeSlot>> dayBreaks,
    required Map<String, bool> markAsOff,
    required Map<String, List<String>> everyOptions,
    required BuildContext context,
    required String bufferTimeMinutes,
    required bool isActive,
  }) {
    if (shiftName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a shift name")),
      );
      return null;
    }

    final Map<WeekDay, DaySchedule> schedule = {};

    for (int i = 0; i < weekDays.length; i++) {
      final dayName = weekDays[i];
      final weekDay = WeekDay.values[i];
      final isOff = markAsOff[dayName] ?? false;
      final offs = everyOptions[dayName] ?? [];

      if (isOff && offs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Select an off-week option for $dayName")),
        );
        return null;
      }

      // Entire day off (Every or empty)
      if (isOff && (offs.isEmpty || offs.contains("Every"))) {
        schedule[weekDay] = DaySchedule(
          day: weekDay,
          isOff: true,
          shifts: [],
          breaks: [],
        );
        continue;
      }

      // --- Convert Shifts ---
      final shifts = _convertShiftTimes(
        dayName: dayName,
        dayShifts: dayShifts,
        context: context,
      );
      if (shifts == null) return null;

      // --- Convert Breaks ---
      final breaks = _convertBreakTimes(
        dayName: dayName,
        dayBreaks: dayBreaks,
        context: context,
      );
      if (breaks == null) return null;

      schedule[weekDay] = DaySchedule(
        day: weekDay,
        isOff: false,
        shifts: shifts,
        breaks: breaks,
        offWeeks: offs.isNotEmpty ? offs : null,
      );
    }

    return {
      "shiftName": shiftName.trim(),
      "description": description.trim(),
      "bufferTimeMinutes": bufferTimeMinutes,
      "isActive": isActive,
      "weekSchedule": schedule.map((k, v) => MapEntry(k.name, v.toMap())),
      "updatedAt": DateTime.now(),
    };
  }

  // ------------------------------------------------------------
  // SHIFT TIME CONVERSION
  // ------------------------------------------------------------
  static List<ShiftTime>? _convertShiftTimes({
    required String dayName,
    required Map<String, List<ShiftTimeSlot>> dayShifts,
    required BuildContext context,
  }) {
    final list = <ShiftTime>[];

    for (var slot in dayShifts[dayName]!) {
      if (slot.startController.text.isEmpty || slot.endController.text.isEmpty)
        continue;

      try {
        final s = slot.startController.text.split(":");
        final e = slot.endController.text.split(":");

        list.add(
          ShiftTime(
            startTime: CustomTimeOfDay(
              hour: int.parse(s[0]),
              minute: int.parse(s[1]),
            ),
            endTime: CustomTimeOfDay(
              hour: int.parse(e[0]),
              minute: int.parse(e[1]),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid shift time format for $dayName")),
        );
        return null;
      }
    }

    return list;
  }

  // ------------------------------------------------------------
  // BREAK TIME CONVERSION
  // ------------------------------------------------------------
  static List<BreakTime>? _convertBreakTimes({
    required String dayName,
    required Map<String, List<BreakTimeSlot>> dayBreaks,
    required BuildContext context,
  }) {
    final list = <BreakTime>[];

    for (var slot in dayBreaks[dayName]!) {
      if (slot.startController.text.isEmpty || slot.endController.text.isEmpty)
        continue;

      try {
        final s = slot.startController.text.split(":");
        final e = slot.endController.text.split(":");

        list.add(
          BreakTime(
            startTime: CustomTimeOfDay(
              hour: int.parse(s[0]),
              minute: int.parse(s[1]),
            ),
            endTime: CustomTimeOfDay(
              hour: int.parse(e[0]),
              minute: int.parse(e[1]),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid break time format for $dayName")),
        );
        return null;
      }
    }

    return list;
  }
}
