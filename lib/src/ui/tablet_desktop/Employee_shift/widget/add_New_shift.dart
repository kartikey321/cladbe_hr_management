import 'package:cladbe_hr_management/src/models/weekly_shift_model.dart'
    as model;
import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexify/hexify.dart';
import 'package:provider/provider.dart';

class AddNewShift extends StatefulWidget {
  const AddNewShift({super.key});

  @override
  State<AddNewShift> createState() => _AddNewShiftState();
}

class _AddNewShiftState extends State<AddNewShift> {
  final TextEditingController _shiftNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  int? _expandedDayIndex;
  final Map<String, List<ShiftTimeSlot>> _dayShifts = {};
  final Map<String, List<BreakTimeSlot>> _dayBreaks = {};
  final Map<String, bool> _markAsOff = {};
  final Map<String, List<String>> _everyOptions = {};
  final Map<String, MultiSelectController> _everyControllers = {};
  final Map<String, bool> _sameAsAbove = {};
  final Map<String, String> _copyFromDay = {};
  final Map<String, MultiSelectController> _copyDayControllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    for (var day in _weekDays) {
      _dayShifts[day] = [ShiftTimeSlot()];
      _dayBreaks[day] = [BreakTimeSlot()];
      _markAsOff[day] = false;
      _everyOptions[day] = [];
      _everyControllers[day] = MultiSelectController();
      _sameAsAbove[day] = false;
      _copyFromDay[day] = 'Monday';
      _copyDayControllers[day] = MultiSelectController();
    }
  }

  void _copyScheduleFromDay(String toDay, String fromDay) {
    setState(() {
      // Clear existing shifts and breaks
      _dayShifts[toDay]!.clear();
      _dayBreaks[toDay]!.clear();

      // Copy shifts
      for (var shift in _dayShifts[fromDay]!) {
        _dayShifts[toDay]!.add(ShiftTimeSlot()
          ..startController.text = shift.startController.text
          ..endController.text = shift.endController.text);
      }

      // Copy breaks
      for (var breakSlot in _dayBreaks[fromDay]!) {
        _dayBreaks[toDay]!.add(BreakTimeSlot()
          ..startController.text = breakSlot.startController.text
          ..endController.text = breakSlot.endController.text);
      }

      // Copy mark as off and every options
      _markAsOff[toDay] = _markAsOff[fromDay]!;
      _everyOptions[toDay] = List.from(_everyOptions[fromDay]!);
    });
  }

  model.WeeklyShiftModel? _convertToModel() {
    // Validate shift name
    if (_shiftNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a shift name')),
      );
      return null;
    }

    final weekSchedule = <model.WeekDay, model.DaySchedule>{};

    for (int i = 0; i < _weekDays.length; i++) {
      final dayName = _weekDays[i];
      final weekDay = model.WeekDay.values[i];
      final isOff = _markAsOff[dayName] ?? false;

      // If day is marked as off, set empty shifts and breaks
      if (isOff) {
        weekSchedule[weekDay] = model.DaySchedule(
          day: weekDay,
          isOff: true,
          shifts: [],
          breaks: [],
        );
        continue;
      }

      // Convert shift times
      final shifts = <model.ShiftTime>[];
      for (var slot in _dayShifts[dayName]!) {
        if (slot.startController.text.isNotEmpty &&
            slot.endController.text.isNotEmpty) {
          try {
            final startParts = slot.startController.text.split(':');
            final endParts = slot.endController.text.split(':');

            shifts.add(model.ShiftTime(
              startTime: model.TimeOfDay(
                hour: int.parse(startParts[0]),
                minute: int.parse(startParts[1]),
              ),
              endTime: model.TimeOfDay(
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

      // Convert break times
      final breaks = <model.BreakTime>[];
      for (var slot in _dayBreaks[dayName]!) {
        if (slot.startController.text.isNotEmpty &&
            slot.endController.text.isNotEmpty) {
          try {
            final startParts = slot.startController.text.split(':');
            final endParts = slot.endController.text.split(':');

            breaks.add(model.BreakTime(
              startTime: model.TimeOfDay(
                hour: int.parse(startParts[0]),
                minute: int.parse(startParts[1]),
              ),
              endTime: model.TimeOfDay(
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

      weekSchedule[weekDay] = model.DaySchedule(
        day: weekDay,
        isOff: false,
        shifts: shifts,
        breaks: breaks,
      );
    }

    return model.WeeklyShiftModel(
      shiftName: _shiftNameController.text.trim(),
      description: _descriptionController.text.trim(),
      weekSchedule: weekSchedule,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _handleAdd() {
    final model = _convertToModel();
    if (model != null) {
      // Close the popup and return the model
      Navigator.of(context).pop(model);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        maxWidth: 1100,
      ),
      decoration: BoxDecoration(
        gradient: Hexify(
          gradientType: HexifyGradientType.linearGradient,
          firstColor: '#2C2D37',
          secondColor: '#26262D',
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF454545)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: AppDefault.dialogHeaderGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                Text(
                  "Add Shift",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () =>
                      Provider.of<PopupProvider>(context, listen: false)
                          .popPopupStack(),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shift Name
                  CustomTextFormField(
                    controller: _shiftNameController,
                    title: 'Shift Name',
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  CustomTextFormField(
                    controller: _descriptionController,
                    title: 'Description',
                    maxLines: 3,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 24),

                  // Shift Schedule
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Shift Schedule",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Week Days
                  ..._weekDays.asMap().entries.map((entry) {
                    int index = entry.key;
                    String day = entry.value;
                    return _buildDaySchedule(day, index);
                  }),

                  const SizedBox(height: 24),

                  // Add Button
                  Center(
                    child: SizedBox(
                      width: 120,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle add shift
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A67D8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Add",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(String day, int index) {
    bool isExpanded = _expandedDayIndex == index;
    bool isFirstDay = index == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF454545)),
      ),
      child: Column(
        children: [
          // Day Header
          InkWell(
            onTap: () {
              setState(() {
                _expandedDayIndex = isExpanded ? null : index;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    day,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (isExpanded) ...[
            const Divider(color: Color(0xFF454545), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Same As Above (only for days after Monday)
                  if (!isFirstDay) ...[
                    Row(
                      children: [
                        Text(
                          "Same As Above",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _sameAsAbove[day] ?? false,
                          onChanged: (value) {
                            setState(() {
                              _sameAsAbove[day] = value;
                              if (value) {
                                _copyScheduleFromDay(day, _copyFromDay[day]!);
                              }
                            });
                          },
                          activeThumbColor: const Color(0xFF5A67D8),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 120,
                          child: DropdownTextField(
                            dropdown: true,
                            dropdownEnabled: _sameAsAbove[day] ?? false,
                            dropdownController: _copyDayControllers[day],
                            dropdownItems: _weekDays
                                .where((d) =>
                                    _weekDays.indexOf(d) <
                                    _weekDays.indexOf(day))
                                .toList(),
                            selectedDropdownItems: [_copyFromDay[day]!],
                            hint: 'Select Day',
                            onOptionSelected: (List<String> selected) {
                              if (selected.isNotEmpty) {
                                setState(() {
                                  _copyFromDay[day] = selected.first;
                                  if (_sameAsAbove[day] ?? false) {
                                    _copyScheduleFromDay(day, selected.first);
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Shift and Break sections side by side
                  Opacity(
                    opacity: (_markAsOff[day] ?? false) ? 0.4 : 1.0,
                    child: IgnorePointer(
                      ignoring: _markAsOff[day] ?? false,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shifts Section (Left)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 25, vertical: 17),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF454545),
                                    width: 1,
                                  ),
                                  gradient: AppDefault.dialogHeaderGradient,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  )),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Shift",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _dayShifts[day]!
                                                .add(ShiftTimeSlot());
                                          });
                                        },
                                        child: Text(
                                          "+ Shift",
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF5A67D8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Shift Time Slots
                                  ..._dayShifts[day]!
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    int slotIndex = entry.key;
                                    return _buildShiftTimeSlot(day, slotIndex);
                                  }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Breaks Section (Right)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 25, vertical: 17),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF454545),
                                    width: 1,
                                  ),
                                  gradient: AppDefault.dialogHeaderGradient,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  )),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Break",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _dayBreaks[day]!
                                                .add(BreakTimeSlot());
                                          });
                                        },
                                        child: Text(
                                          "+ Break",
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF5A67D8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Break Time Slots
                                  ..._dayBreaks[day]!
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    int slotIndex = entry.key;
                                    return _buildBreakTimeSlot(day, slotIndex);
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mark As Off and Every
                  Row(
                    spacing: 10,
                    children: [
                      Container(
                        height: 43,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withValues(alpha: 0.02),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              "Mark As Off",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Checkbox(
                              value: _markAsOff[day] ?? false,
                              onChanged: (value) {
                                setState(() {
                                  _markAsOff[day] = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFF5A67D8),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.7),
                                width: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: (_markAsOff[day] ?? false)
                              ? const Color(0xFF2C2D35)
                              : Colors.white.withValues(alpha: 0.01),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        width: 150,
                        child: DropdownTextField(
                          dropdown: true,
                          dropdownEnabled: _markAsOff[day] ?? false,
                          dropdownController: _everyControllers[day],
                          selectionType: SelectionType.multi,
                          dropdownItems: const [
                            'Every',
                            '1st',
                            '2nd',
                            '3rd',
                            '4th',
                          ],
                          selectedDropdownItems: _everyOptions[day]!,
                          hint: 'Select',
                          onOptionSelected: (List<String> selected) {
                            setState(() {
                              _everyOptions[day] = selected;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShiftTimeSlot(String day, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Text(
              "0${index + 1}",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Shift Start Column
          Expanded(
            child: DropdownTextField(
              name: "Shift Start",
              nameStyle: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
              controller: _dayShifts[day]![index].startController,
              textFieldHint: "HH:MM",
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
                if (!timeRegex.hasMatch(value)) {
                  return 'Invalid time format (HH:MM)';
                }
                return null;
              },
              suffix: IconButton(
                icon: const Icon(Icons.access_time, color: Color(0xFF5A67D8)),
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    _dayShifts[day]![index].startController.text =
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Shift End Column
          Expanded(
            child: DropdownTextField(
              name: "Shift End",
              nameStyle: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
              controller: _dayShifts[day]![index].endController,
              textFieldHint: "HH:MM",
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
                if (!timeRegex.hasMatch(value)) {
                  return 'Invalid time format (HH:MM)';
                }
                return null;
              },
              suffix: IconButton(
                icon: const Icon(Icons.access_time, color: Color(0xFF5A67D8)),
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    _dayShifts[day]![index].endController.text =
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          if (_dayShifts[day]!.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _dayShifts[day]!.removeAt(index);
                  });
                },
                child: Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBreakTimeSlot(String day, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Text(
              "0${index + 1}",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Break Start Column
          Expanded(
            child: DropdownTextField(
              name: "Break Start",
              nameStyle: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
              controller: _dayBreaks[day]![index].startController,
              textFieldHint: "HH:MM",
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
                if (!timeRegex.hasMatch(value)) {
                  return 'Invalid time format (HH:MM)';
                }
                return null;
              },
              suffix: IconButton(
                icon: const Icon(Icons.access_time, color: Color(0xFF5A67D8)),
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    _dayBreaks[day]![index].startController.text =
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Break End Column
          Expanded(
            child: DropdownTextField(
              name: "Break End",
              nameStyle: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
              controller: _dayBreaks[day]![index].endController,
              textFieldHint: "HH:MM",
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
                if (!timeRegex.hasMatch(value)) {
                  return 'Invalid time format (HH:MM)';
                }
                return null;
              },
              suffix: IconButton(
                icon: const Icon(Icons.access_time, color: Color(0xFF5A67D8)),
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    _dayBreaks[day]![index].endController.text =
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          if (_dayBreaks[day]!.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _dayBreaks[day]!.removeAt(index);
                  });
                },
                child: Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _shiftNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class ShiftTimeSlot {
  TextEditingController startController = TextEditingController();
  TextEditingController endController = TextEditingController();
}

class BreakTimeSlot {
  TextEditingController startController = TextEditingController();
  TextEditingController endController = TextEditingController();
}
