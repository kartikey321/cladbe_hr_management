import 'package:cladbe_hr_management/src/Helpers/holidays_helper.dart';
import 'package:cladbe_hr_management/src/ui/tablet_desktop/Holiday/services/holiday_converter_rowServices.dart';
import 'package:cladbe_hr_management/src/ui/widgets/Combined_dropdown.dart';
import 'package:cladbe_hr_management/src/ui/widgets/dropdownTextfield.dart';
import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hexify/hexify.dart';
import 'package:intl/intl.dart';
import 'package:cladbe_shared/src/models/Attendance/Holiday/holiday.dart';

class AddHoliday extends StatefulWidget {
  final HolidayModel? holiday;
  final String? holidayId;

  const AddHoliday({
    super.key,
    this.holiday,
    this.holidayId,
  });

  @override
  State<AddHoliday> createState() => _AddHolidayState();
}

class _AddHolidayState extends State<AddHoliday> {
  // Controllers
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Leave rows
  List<LeaveRow> leaveRows = [LeaveRow()];
  // Occasion rows
  List<OccasionRow> occasionRows = [OccasionRow()];
  HolidayModel? holiday;
  String format(DateTime? date) =>
      date == null ? "" : DateFormat("dd/MM/yyyy").format(date);

  Future<void> onAddHoliday(HolidayModel holiday) async {
    await HolidaysHelper.addHoliday(
        companyId: context.getCompanyId(), holiday: holiday);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Holiday added successfully")),
    );
  }

  @override
  void initState() {
    if (widget.holiday != null) {
      _loadExistingHoliday(widget.holiday!);
    }
    super.initState();
  }

// put this inside _AddHolidayState
  void _loadExistingHoliday(HolidayModel model) {
    // basic fields
    _departmentController.text = model.name;
    _descriptionController.text = model.description ?? '';

    // ---- LEAVES: recreate rows ----
    leaveRows = [];

    for (var leave in model.leaves) {
      final row = LeaveRow();

      // transferable + amount
      row.transferable = leave.transferable;
      row.daysController.text = leave.amountOfDays.toString();

      // leave name (right side suggestion field)
      row.leaveNameController.text = leave.leaveName;
      // try to map to enum if you have an enum mapping; fallback to null:
      try {
        row.selectedLeaveName = LeaveName.values.firstWhere(
          (e) => e.displayName == leave.leaveName || e.name == leave.leaveName,
        );
      } catch (_) {
        row.selectedLeaveName = null;
      }

      // leave type (enum)
      row.selectedLeaveType = leave.type;

      // IMPORTANT: set options & selected options on the MultiSelectController
      // The DropdownTextField / MultiSelect expects ValueItem entries.
      final typeLabel = row.selectedLeaveType?.displayName ?? leave.type.name;
      final valueItem = ValueItem(label: typeLabel, value: typeLabel);

      // set available option(s) and mark it selected
      row.leaveTypeController.clearAllSelection();
      row.leaveTypeController.setOptions([valueItem]);
      row.leaveTypeController.setSelectedOptions([valueItem]);

      leaveRows.add(row);
    }

    // Ensure at least one row exists
    if (leaveRows.isEmpty) leaveRows = [LeaveRow()];

    // ---- OCCASIONS: recreate rows ----
    occasionRows = [];

    for (var occ in model.occasions) {
      final row = OccasionRow();

      // name
      row.nameController.text = occ.name;

      // start / end dates
      row.startDate = occ.startDate;
      row.endDate = occ.endDate;

      // format controllers (same format helper you already have)
      row.startDateController.text = format(row.startDate);
      row.endDateController.text = format(row.endDate);

      occasionRows.add(row);
    }

    // Ensure at least one occasion row exists
    if (occasionRows.isEmpty) occasionRows = [OccasionRow()];

    // refresh UI
    setState(() {});
  }

  Future<void> onSubmit(HolidayModel model) async {
    if (widget.holiday == null) {
      /// -------- ADD MODE --------
      await HolidaysHelper.addHoliday(
        companyId: context.getCompanyId(),
        holiday: model,
      );

      showCustomSnackBarOverlay(
        "Holiday added successfully",
        status: SnackBarStatus.success,
      );
    } else {
      /// -------- UPDATE MODE --------
      await HolidaysHelper.updateHoliday(
        companyId: context.getCompanyId(),
        holidayId: widget.holidayId!,
        holidayUpdates: model.toMap(),
      );

      showCustomSnackBarOverlay(
        "Holiday updated successfully",
        status: SnackBarStatus.success,
      );
    }

    NavigatorHelper.navigateBack(context);
    // /// Close popup if needed
    // Provider.of<PopupProvider>(context, listen: false).popPopupStack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDefault.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  spacing: 15,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Department
                    Row(
                      spacing: 10,
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownTextField(
                            controller: _departmentController,
                            hint: "Name",
                            name: "Name",
                          ),
                        ),
                        const SizedBox(height: 24),

                        /// Description
                        Expanded(
                          flex: 4,
                          child: DropdownTextField(
                            controller: _descriptionController,
                            name: "Description",
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      spacing: 11,
                      children: [
                        const Icon(
                          Icons.holiday_village_outlined,
                          color: Colors.white70,
                        ),
                        Text(
                          "Holiday Details",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppDefault.dividerColor),

                    /// LEAVE SECTION
                    _buildLeaveContainer(),

                    /// OCCASION SECTION
                    _buildOccasionContainer(),

                    const SizedBox(height: 40),

                    /// Add Button
                    Center(
                      child: SizedBox(
                        width: 160,
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Hexify(colorCode: "#5A67D8"),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            final validation = HolidayConverter.validate(
                              name: _departmentController.text,
                              description: _descriptionController.text,
                              leaveRows: leaveRows,
                              occasionRows: occasionRows,
                            );

                            if (validation!["success"] == false) {
                              List<String> errors = validation["errors"];
                              showCustomSnackBarOverlay(
                                errors.first,
                                status: SnackBarStatus.error,
                              );
                              return;
                            }

                            /// Convert to model
                            final model = HolidayConverter.convertToModel(
                              name: _departmentController.text,
                              description: _descriptionController.text,
                              leaveRows: leaveRows,
                              occasionRows: occasionRows,
                              existingId:
                                  widget.holidayId, // preserve ID on update
                            );
                            onSubmit(model);
                          },
                          child: Text(
                            widget.holiday == null ? "Add" : "Update",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Container(
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
            "Add Holiday",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () => Provider.of<PopupProvider>(context, listen: false)
                .popPopupStack(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LEAVE SECTION
  // ---------------------------------------------------------------------------

  Widget _buildLeaveContainer() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Hexify(colorCode: '#1C1D23'),
            Hexify(colorCode: '#2C2D35'),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Title + Add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Leave",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),

              /// Add Leave Row
              InkWell(
                onTap: () {
                  setState(() => leaveRows.add(LeaveRow()));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Hexify(colorCode: "#FFFFFF", opacity: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "+ Leave",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          /// Leave Rows
          for (int i = 0; i < leaveRows.length; i++) _buildLeaveRow(i),
        ],
      ),
    );
  }

  Widget _buildLeaveRow(int index) {
    final row = leaveRows[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  spacing: 9,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Type",
                          style: GoogleFonts.poppins(color: Colors.white70),
                        ),
                        Row(
                          spacing: 15,
                          children: [
                            Text(
                              "Transferable",
                              style: GoogleFonts.poppins(color: Colors.white70),
                            ),
                            CustomSwitchButton(
                              defaultValue: row.transferable,
                              onChanged: (v) =>
                                  setState(() => row.transferable = v),
                            ),
                            if (leaveRows.length > 1)
                              InkWell(
                                onTap: () {
                                  setState(() => leaveRows.removeAt(index));
                                },
                                child: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.redAccent,
                                  size: 22,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    CombinedDropdownField(
                      leftLabel: "Leave Type",
                      leftItems:
                          LeaveType.values.map((e) => e.displayName).toList(),
                      leftController: row.leaveTypeController,
                      onLeftSelected: (items) {
                        setState(() {
                          final value = items.first;
                          row.selectedLeaveType = LeaveType.values.firstWhere(
                            (e) => e.displayName == value,
                          );
                        });
                      },
                      useSuggestionField: true,
                      rightLabel: "Leave Name",
                      rightTextController: row.leaveNameController,
                      rightItems:
                          LeaveName.values.map((e) => e.displayName).toList(),
                      onRightSelected: (name) {
                        setState(() {
                          row.selectedLeaveName = LeaveName.values.firstWhere(
                            (e) => e.displayName == name,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 50),

              /// Amount of days
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 13),
                    Text("Amount of days",
                        style: GoogleFonts.poppins(color: Colors.white70)),
                    const SizedBox(height: 5),
                    DropdownTextField(
                      controller: row.daysController,
                      keyboardType: TextInputType.number,
                      inputFormatter: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OCCASION SECTION
  // ---------------------------------------------------------------------------

  Widget _buildOccasionContainer() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Hexify(colorCode: '#1C1D23'),
            Hexify(colorCode: '#2C2D35'),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Title + Add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Occasion",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              InkWell(
                onTap: () => setState(() => occasionRows.add(OccasionRow())),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Hexify(colorCode: "#FFFFFF", opacity: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "+ Occasion",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          for (int i = 0; i < occasionRows.length; i++) _buildOccasionRow(i),
          Text(
            "Total Occasion Holidays: ${getTotalOccasionDays()} ${getTotalOccasionDays() == 1 ? 'day' : 'days'}",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccasionRow(int index) {
    final row = occasionRows[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          /// Occasion Name
          Expanded(
            flex: 3,
            child: DropdownTextField(
              name: "Occasion Name",
              controller: row.nameController,
            ),
          ),
          const SizedBox(width: 12),

          /// START DATE
          Expanded(
            flex: 2,
            child: DropdownTextField(
              name: "Start Date",
              textFieldEnabled: false,
              controller: row.startDateController,
              suffix: IconButton(
                icon: const Icon(Icons.calendar_month, color: Colors.white70),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: row.startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    setState(() {
                      row.startDate = picked;
                      row.startDateController.text = format(picked);

                      /// Prevent invalid end date
                      if (row.endDate != null &&
                          row.endDate!.isBefore(picked)) {
                        row.endDate = picked;
                        row.endDateController.text = format(picked);
                      }
                    });
                  }
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          /// END DATE
          Expanded(
            flex: 2,
            child: DropdownTextField(
              name: "End Date",
              textFieldEnabled: false,
              controller: row.endDateController,
              suffix: IconButton(
                icon: const Icon(Icons.calendar_month, color: Colors.white70),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: row.endDate ?? row.startDate ?? DateTime.now(),
                    firstDate: row.startDate ?? DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    setState(() {
                      row.endDate = picked;
                      row.endDateController.text = format(picked);
                    });
                  }
                },
              ),
            ),
          ),

          if (occasionRows.length > 1) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => setState(() => occasionRows.removeAt(index)),
              child: const Icon(Icons.remove_circle, color: Colors.redAccent),
            ),
          ]
        ],
      ),
    );
  }

  int getTotalOccasionDays() {
    int total = 0;

    for (var row in occasionRows) {
      if (row.startDate != null && row.endDate != null) {
        total +=
            row.endDate!.difference(row.startDate!).inDays + 1; // inclusive
      }
    }

    return total;
  }
}
