import 'package:cladbe_hr_management/src/ui/tablet_desktop/Employee_shift/services/shift_converter_service.dart';
import 'package:cladbe_hr_management/src/ui/tablet_desktop/Employee_shift/widget/time_slot_models.dart';
import 'package:cladbe_hr_management/src/ui/widgets/timePicker.dart';
import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexify/hexify.dart';
import 'package:provider/provider.dart';

class AddNewShift extends StatefulWidget {
  final WeeklyShiftModel? shiftModel;

  const AddNewShift({super.key, this.shiftModel});

  @override
  State<AddNewShift> createState() => _AddNewShiftState();
}

class _AddNewShiftState extends State<AddNewShift> with SuperMixin {
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
  final TextEditingController _bufferTimeController =
      TextEditingController(text: '0');

  bool _isActive = true;

  @override
  void initState() {
    super.initState();

    // Default init
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

    // Load if editing
    if (widget.shiftModel != null) {
      _loadExistingShift(widget.shiftModel!);
    }
  }

  void _loadExistingShift(WeeklyShiftModel s) {
    _shiftNameController.text = s.shiftName;
    _descriptionController.text = s.description ?? '';
    _bufferTimeController.text = s.bufferTimeMinutes;
    _isActive = s.isActive;

    for (var entry in s.weekSchedule.entries) {
      String day = entry.key.displayName;
      DaySchedule data = entry.value;

      /// MARK AS OFF
      _markAsOff[day] = data.isOff;

      /// Store raw selected week options coming from DB
      _everyOptions[day] = List<String>.from(data.offWeeks ?? []);

      // ---------------------------------------------------------------
      // FIXED: Setup dropdown options & restore selected values
      // ---------------------------------------------------------------
      final availableOptions = [
        "Every",
        "1st",
        "2nd",
        "3rd",
        "4th",
      ].map((e) => ValueItem(label: e, value: e)).toList();

      final controller = _everyControllers[day]!;
      controller.setOptions(availableOptions);
      controller.clearAllSelection();

      final selected = _everyOptions[day]!
          .map((item) => ValueItem(label: item, value: item))
          .toList();

      if (selected.isNotEmpty) {
        controller.setSelectedOptions(selected);
      }

      // ---------------------------------------------------------------
      // REBUILD SHIFT ROWS
      // ---------------------------------------------------------------
      _dayShifts[day] = [];

      for (var sh in data.shifts) {
        var slot = ShiftTimeSlot();
        slot.startController.text = _fmtCustom(sh.startTime);
        slot.endController.text = _fmtCustom(sh.endTime);
        _dayShifts[day]!.add(slot);
      }

      if (_dayShifts[day]!.isEmpty) {
        _dayShifts[day]!.add(ShiftTimeSlot());
      }

      // ---------------------------------------------------------------
      // REBUILD BREAK ROWS
      // ---------------------------------------------------------------
      _dayBreaks[day] = [];

      for (var br in data.breaks) {
        var slot = BreakTimeSlot();
        slot.startController.text = _fmtCustom(br.startTime);
        slot.endController.text = _fmtCustom(br.endTime);
        _dayBreaks[day]!.add(slot);
      }

      if (_dayBreaks[day]!.isEmpty) {
        _dayBreaks[day]!.add(BreakTimeSlot());
      }
    }

    setState(() {});
  }

  String _fmtCustom(CustomTimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
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

  // Disable "Same As Above" when user makes changes
  void _disableSameAsAbove(String day) {
    if (_sameAsAbove[day] ?? false) {
      setState(() {
        _sameAsAbove[day] = false;
      });
    }
  }

  Map<String, dynamic>? _convertToModel() {
    return ShiftConverterService.convertToMap(
      shiftName: _shiftNameController.text,
      description: _descriptionController.text,
      weekDays: _weekDays,
      dayShifts: _dayShifts,
      dayBreaks: _dayBreaks,
      markAsOff: _markAsOff,
      everyOptions: _everyOptions,
      context: context,
      bufferTimeMinutes: _bufferTimeController.text,
      isActive: _isActive,
    );
  }

  void _saveShift() async {
    final updateMap = _convertToModel();
    if (updateMap == null) return;

    try {
      // ---------------- CREATE ----------------
      if (widget.shiftModel == null) {
        final newShift = WeeklyShiftModel(
          id: generateUniqueId(),
          shiftName: updateMap["shiftName"],
          description: updateMap["description"],
          weekSchedule:
              WeeklyShiftModel.parseWeekSchedule(updateMap["weekSchedule"]),
          bufferTimeMinutes: updateMap["bufferTimeMinutes"],
          isActive: updateMap["isActive"],
          createdAt: ServerTimeService.instance.currentServerTime,
          updatedAt: ServerTimeService.instance.currentServerTime,
        );

        await ShiftHelper.addShift(
          companyId: context.getCompanyId(),
          weeklyShift: newShift,
        );

        showSnackBar("Shift added successfully",
            snackBarStatus: SnackBarStatus.success);
        NavigatorHelper.navigateBack(context);
        Provider.of<PopupProvider>(context, listen: false).popPopupStack();
        return;
      }

      // ---------------- UPDATE USING copyWith ----------------
      final updatedShift = widget.shiftModel!.copyWith(
        shiftName: updateMap["shiftName"],
        description: updateMap["description"],
        weekSchedule:
            WeeklyShiftModel.parseWeekSchedule(updateMap["weekSchedule"]),
        bufferTimeMinutes: updateMap["bufferTimeMinutes"],
        isActive: updateMap["isActive"],
        updatedAt: ServerTimeService.instance.currentServerTime,
      );

      await ShiftHelper.updateShift(
        companyId: context.getCompanyId(),
        weekShiftId: widget.shiftModel!.id,
        shiftUpdates: updatedShift.toMap(),
      );

      showSnackBar("Shift updated successfully",
          snackBarStatus: SnackBarStatus.success);

      Provider.of<PopupProvider>(context, listen: false).popPopupStack();
    } catch (e) {
      LoggerService.error("Error saving shift: $e");
      showSnackBar("Error saving shift", snackBarStatus: SnackBarStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDefault.backgroundColor,
      body: Container(
        // constraints: BoxConstraints(
        //   maxHeight: MediaQuery.of(context).size.height * 0.9,
        //   maxWidth: 1100,
        // ),
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
            widget.shiftModel != null
                ? Container(
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
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                          onPressed: () =>
                              Provider.of<PopupProvider>(context, listen: false)
                                  .popPopupStack(),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),

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

                    CustomTextFormField(
                      controller: _descriptionController,
                      title: 'Description',
                      maxLines: 3,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: 16),

                    // 🔥 Active / Inactive Toggle
                    Row(
                      children: [
                        // Text(
                        //   "Shift Active",
                        //   style: GoogleFonts.poppins(
                        //     color: Colors.white,
                        //     fontSize: 14,
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
                        // const SizedBox(width: 12),
                        Switch(
                          value: _isActive,
                          activeThumbColor: const Color(0xFF5A67D8),
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isActive ? "Active" : "Inactive",
                          style: GoogleFonts.poppins(
                            color: _isActive
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 13,
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 24),
                    CustomTextFormField(
                      keyboardType: TextInputType.number,
                      controller: _bufferTimeController,
                      title: 'Buffer Time (in minutes)',
                      autovalidateMode: AutovalidateMode.always,
                      inputFormatter: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],

                      // name: 'Buffer Time',
                      // textFieldEnabled: true,
                    ),
                    const SizedBox(height: 16),
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
                      return buildDaySchedule(day, index);
                    }),

                    const SizedBox(height: 24),

                    // Add Button
                    Center(
                      child: SizedBox(
                        width: 120,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            _saveShift();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A67D8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            widget.shiftModel == null ? "Add" : "Update",
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
      ),
    );
  }

  Widget buildDaySchedule(String day, int index) {
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
                        // Only show dropdown when switch is ON
                        if (_sameAsAbove[day] ?? false)
                          SizedBox(
                            width: 120,
                            child: DropdownTextField(
                              dropdown: true,
                              dropdownEnabled: true,
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
                                    _copyScheduleFromDay(day, selected.first);
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
                  // Only gray out if completely off (no specific weeks selected OR "Every" is selected)
                  Opacity(
                    opacity: (_markAsOff[day] ?? false) &&
                            ((_everyOptions[day]?.isEmpty ?? true) ||
                                (_everyOptions[day]?.contains('Every') ??
                                    false))
                        ? 0.4
                        : 1.0,
                    child: IgnorePointer(
                      ignoring: (_markAsOff[day] ?? false) &&
                          ((_everyOptions[day]?.isEmpty ?? true) ||
                              (_everyOptions[day]?.contains('Every') ?? false)),
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
                                    return buildShiftTimeSlot(day, slotIndex);
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
                                    return buildBreakTimeSlot(day, slotIndex);
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

                                  if (_markAsOff[day] == true) {
                                    // Clear shift/break ONLY if "Every" is selected
                                    if (_everyOptions[day]?.contains('Every') ??
                                        false) {
                                      for (var shift in _dayShifts[day]!) {
                                        shift.startController.clear();
                                        shift.endController.clear();
                                      }
                                      for (var brk in _dayBreaks[day]!) {
                                        brk.startController.clear();
                                        brk.endController.clear();
                                      }
                                    }
                                  } else {
                                    // When OFF is turned OFF → reset dropdown
                                    _everyOptions[day] = [];
                                    _everyControllers[day]!.clearAllSelection();
                                  }
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
                              _disableSameAsAbove(day);

                              // ❗ Only clear shifts/breaks if "Every" is selected
                              if ((_markAsOff[day] ?? false) &&
                                  selected.contains('Every')) {
                                for (var shift in _dayShifts[day]!) {
                                  shift.startController.clear();
                                  shift.endController.clear();
                                }
                                for (var brk in _dayBreaks[day]!) {
                                  brk.startController.clear();
                                  brk.endController.clear();
                                }
                              }
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

  Widget buildShiftTimeSlot(String day, int index) {
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
              textFieldEnabled: false,
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
                  final time =
                      await CustomTimepicker.showThemedTimePicker(context);
                  if (time != null) {
                    setState(() {
                      _dayShifts[day]![index].startController.text =
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      _disableSameAsAbove(day);
                    });
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
              textFieldEnabled: false,
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
                  final time =
                      await CustomTimepicker.showThemedTimePicker(context);
                  if (time != null) {
                    setState(() {
                      _dayShifts[day]![index].endController.text =
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      _disableSameAsAbove(day);
                    });
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

  Widget buildBreakTimeSlot(String day, int index) {
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
              textFieldEnabled: false,
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
                  final time =
                      await CustomTimepicker.showThemedTimePicker(context);
                  if (time != null) {
                    setState(() {
                      _dayBreaks[day]![index].startController.text =
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      _disableSameAsAbove(day);
                    });
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
              textFieldEnabled: false,
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
                  final time =
                      await CustomTimepicker.showThemedTimePicker(context);
                  if (time != null) {
                    setState(() {
                      _dayBreaks[day]![index].endController.text =
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      _disableSameAsAbove(day);
                    });
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

    // Dispose all shift and break controllers
    for (var dayShifts in _dayShifts.values) {
      for (var shift in dayShifts) {
        shift.dispose();
      }
    }
    for (var dayBreaks in _dayBreaks.values) {
      for (var breakSlot in dayBreaks) {
        breakSlot.dispose();
      }
    }

    super.dispose();
  }
}
