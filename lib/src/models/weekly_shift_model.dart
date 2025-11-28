/// Main model for Weekly Shift configuration
class WeeklyShiftModel {
  final String? id;
  final String shiftName;
  final String? description;
  final Map<WeekDay, DaySchedule> weekSchedule;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WeeklyShiftModel({
    this.id,
    required this.shiftName,
    this.description,
    required this.weekSchedule,
    this.createdAt,
    this.updatedAt,
  });

  factory WeeklyShiftModel.empty() {
    return WeeklyShiftModel(
      shiftName: '',
      description: '',
      weekSchedule: {
        for (var day in WeekDay.values)
          day: DaySchedule(
            day: day,
            isOff: false,
            shifts: [],
            breaks: [],
          ),
      },
    );
  }

  WeeklyShiftModel copyWith({
    String? id,
    String? shiftName,
    String? description,
    Map<WeekDay, DaySchedule>? weekSchedule,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeeklyShiftModel(
      id: id ?? this.id,
      shiftName: shiftName ?? this.shiftName,
      description: description ?? this.description,
      weekSchedule: weekSchedule ?? this.weekSchedule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shiftName': shiftName,
      'description': description,
      'weekSchedule': weekSchedule.map(
        (key, value) => MapEntry(key.name, value.toMap()),
      ),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory WeeklyShiftModel.fromMap(Map<String, dynamic> map) {
    final weekScheduleData = map['weekSchedule'] as Map<String, dynamic>?;
    final Map<WeekDay, DaySchedule> weekSchedule = {};

    if (weekScheduleData != null) {
      for (var entry in weekScheduleData.entries) {
        final day = WeekDay.values.firstWhere(
          (d) => d.name == entry.key,
          orElse: () => WeekDay.monday,
        );
        weekSchedule[day] = DaySchedule.fromMap(entry.value);
      }
    }

    return WeeklyShiftModel(
      id: map['id'],
      shiftName: map['shiftName'] ?? '',
      description: map['description'],
      weekSchedule: weekSchedule,
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}

/// Model for each day's schedule
class DaySchedule {
  final WeekDay day;
  final bool isOff;
  final List<ShiftTime> shifts;
  final List<BreakTime> breaks;

  DaySchedule({
    required this.day,
    this.isOff = false,
    required this.shifts,
    required this.breaks,
  });

  DaySchedule copyWith({
    WeekDay? day,
    bool? isOff,
    List<ShiftTime>? shifts,
    List<BreakTime>? breaks,
  }) {
    return DaySchedule(
      day: day ?? this.day,
      isOff: isOff ?? this.isOff,
      shifts: shifts ?? this.shifts,
      breaks: breaks ?? this.breaks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day.name,
      'isOff': isOff,
      'shifts': shifts.map((s) => s.toMap()).toList(),
      'breaks': breaks.map((b) => b.toMap()).toList(),
    };
  }

  factory DaySchedule.fromMap(Map<String, dynamic> map) {
    return DaySchedule(
      day: WeekDay.values.firstWhere(
        (d) => d.name == map['day'],
        orElse: () => WeekDay.monday,
      ),
      isOff: map['isOff'] ?? false,
      shifts:
          (map['shifts'] as List?)?.map((s) => ShiftTime.fromMap(s)).toList() ??
              [],
      breaks:
          (map['breaks'] as List?)?.map((b) => BreakTime.fromMap(b)).toList() ??
              [],
    );
  }

  /// Copy settings from another day schedule
  DaySchedule copyFrom(DaySchedule other) {
    return DaySchedule(
      day: day,
      isOff: other.isOff,
      shifts: other.shifts.map((s) => s.copyWith()).toList(),
      breaks: other.breaks.map((b) => b.copyWith()).toList(),
    );
  }
}

/// Model for shift time (start and end)
class ShiftTime {
  final String? id;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  ShiftTime({
    this.id,
    required this.startTime,
    required this.endTime,
  });

  ShiftTime copyWith({
    String? id,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return ShiftTime(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': _timeToString(startTime),
      'endTime': _timeToString(endTime),
    };
  }

  factory ShiftTime.fromMap(Map<String, dynamic> map) {
    return ShiftTime(
      id: map['id'],
      startTime: _stringToTime(map['startTime']),
      endTime: _stringToTime(map['endTime']),
    );
  }

  /// Calculate duration in hours
  double get durationInHours {
    final start = startTime.hour + startTime.minute / 60.0;
    final end = endTime.hour + endTime.minute / 60.0;
    return end >= start ? end - start : (24 - start) + end;
  }

  bool overlaps(ShiftTime other) {
    final thisStart = startTime.hour * 60 + startTime.minute;
    final thisEnd = endTime.hour * 60 + endTime.minute;
    final otherStart = other.startTime.hour * 60 + other.startTime.minute;
    final otherEnd = other.endTime.hour * 60 + other.endTime.minute;

    return (thisStart < otherEnd && thisEnd > otherStart);
  }

  static String _timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static TimeOfDay _stringToTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}

/// Model for break time (start and end)
class BreakTime {
  final String? id;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  BreakTime({
    this.id,
    required this.startTime,
    required this.endTime,
  });

  BreakTime copyWith({
    String? id,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return BreakTime(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': _timeToString(startTime),
      'endTime': _timeToString(endTime),
    };
  }

  factory BreakTime.fromMap(Map<String, dynamic> map) {
    return BreakTime(
      id: map['id'],
      startTime: _stringToTime(map['startTime']),
      endTime: _stringToTime(map['endTime']),
    );
  }

  /// Calculate duration in minutes
  double get durationInMinutes {
    final start = startTime.hour * 60 + startTime.minute;
    final end = endTime.hour * 60 + endTime.minute;
    return (end >= start ? end - start : (24 * 60 - start) + end).toDouble();
  }

  static String _timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static TimeOfDay _stringToTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}

/// Helper class for TimeOfDay since it's from Flutter
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({
    required this.hour,
    required this.minute,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeOfDay &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Enum for days of the week
enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get displayName {
    switch (this) {
      case WeekDay.monday:
        return 'Monday';
      case WeekDay.tuesday:
        return 'Tuesday';
      case WeekDay.wednesday:
        return 'Wednesday';
      case WeekDay.thursday:
        return 'Thursday';
      case WeekDay.friday:
        return 'Friday';
      case WeekDay.saturday:
        return 'Saturday';
      case WeekDay.sunday:
        return 'Sunday';
    }
  }

  String get shortName {
    switch (this) {
      case WeekDay.monday:
        return 'Mon';
      case WeekDay.tuesday:
        return 'Tue';
      case WeekDay.wednesday:
        return 'Wed';
      case WeekDay.thursday:
        return 'Thu';
      case WeekDay.friday:
        return 'Fri';
      case WeekDay.saturday:
        return 'Sat';
      case WeekDay.sunday:
        return 'Sun';
    }
  }
}
