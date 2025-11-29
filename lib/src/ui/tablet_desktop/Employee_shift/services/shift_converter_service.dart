import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:cladbe_shared/src/models/Attendance/weekly_shift_model.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../widget/time_slot_models.dart';

/// Service class to handle conversion between UI models and data models
class ShiftConverterService {
  /// Converts UI shift/break data to WeeklyShiftModel
  static WeeklyShiftModel? convertToModel({
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
    // Validate shift name
    if (shiftName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a shift name')),
      );
      return null;
    }

    final weekSchedule = <WeekDay, DaySchedule>{};

    for (int i = 0; i < weekDays.length; i++) {
      final dayName = weekDays[i];
      final weekDay = WeekDay.values[i];
      final isMarkedOff = markAsOff[dayName] ?? false;
      final options = everyOptions[dayName] ?? [];

      // ❗️VALIDATION: Marked off but no dropdown selected
      if (isMarkedOff && options.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Please select at least one off-week option for $dayName')),
        );
        return null;
      }

      // 🟢 Completely off (Every OR empty)
      if (isMarkedOff && (options.isEmpty || options.contains('Every'))) {
        weekSchedule[weekDay] = DaySchedule(
          day: weekDay,
          isOff: true,
          shifts: [],
          breaks: [],
        );
        continue;
      }

      // Convert shift times
      final shifts = _convertShiftTimes(
        dayName: dayName,
        dayShifts: dayShifts,
        context: context,
      );
      if (shifts == null) return null;

      // Convert break times
      final breaks = _convertBreakTimes(
        dayName: dayName,
        dayBreaks: dayBreaks,
        context: context,
      );
      if (breaks == null) return null;

      // Marked off only for specific weeks
      weekSchedule[weekDay] = DaySchedule(
        day: weekDay,
        isOff: false,
        shifts: shifts,
        breaks: breaks,
        offWeeks: isMarkedOff && options.isNotEmpty ? options : null,
      );
    }

    return WeeklyShiftModel(
        id: generateUniqueId(),
        shiftName: shiftName.trim(),
        description: description.trim(),
        weekSchedule: weekSchedule,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bufferTimeMinutes: bufferTimeMinutes,
        isActive: isActive);
  }

  /// Converts shift time slots to ShiftTime models
  static List<ShiftTime>? _convertShiftTimes({
    required String dayName,
    required Map<String, List<ShiftTimeSlot>> dayShifts,
    required BuildContext context,
  }) {
    final shifts = <ShiftTime>[];

    for (var slot in dayShifts[dayName]!) {
      if (slot.startController.text.isNotEmpty &&
          slot.endController.text.isNotEmpty) {
        try {
          final startParts = slot.startController.text.split(':');
          final endParts = slot.endController.text.split(':');

          shifts.add(ShiftTime(
            startTime: CustomTimeOfDay(
              hour: int.parse(startParts[0]),
              minute: int.parse(startParts[1]),
            ),
            endTime: CustomTimeOfDay(
              hour: int.parse(endParts[0]),
              minute: int.parse(endParts[1]),
            ),
          ));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid time format for $dayName shift')),
          );
          return null;
        }
      }
    }

    return shifts;
  }

  /// Converts break time slots to BreakTime models
  static List<BreakTime>? _convertBreakTimes({
    required String dayName,
    required Map<String, List<BreakTimeSlot>> dayBreaks,
    required BuildContext context,
  }) {
    final breaks = <BreakTime>[];

    for (var slot in dayBreaks[dayName]!) {
      if (slot.startController.text.isNotEmpty &&
          slot.endController.text.isNotEmpty) {
        try {
          final startParts = slot.startController.text.split(':');
          final endParts = slot.endController.text.split(':');

          breaks.add(BreakTime(
            startTime: CustomTimeOfDay(
              hour: int.parse(startParts[0]),
              minute: int.parse(startParts[1]),
            ),
            endTime: CustomTimeOfDay(
              hour: int.parse(endParts[0]),
              minute: int.parse(endParts[1]),
            ),
          ));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid time format for $dayName break')),
          );
          return null;
        }
      }
    }

    return breaks;
  }
}
