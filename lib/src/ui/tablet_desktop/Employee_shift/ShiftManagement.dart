import 'package:cladbe_hr_management/src/Helpers/shift_helper.dart';
import 'package:cladbe_hr_management/src/routes/route_config/route_names.dart';
import 'package:cladbe_hr_management/src/ui/tablet_desktop/Employee_shift/widget/add_New_shift.dart';
import 'package:cladbe_hr_management/src/ui/tablet_desktop/Employee_shift/widget/shift_card.dart';
import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexify/hexify.dart';
import 'package:provider/provider.dart';

class ShiftManagement extends StatefulWidget {
  const ShiftManagement({
    super.key,
  });

  @override
  State<ShiftManagement> createState() => _ShiftManagementState();
}

class _ShiftManagementState extends State<ShiftManagement> {
  List<WeeklyShiftModel> shifts = [];

  Stream<List<WeeklyShiftModel>>? shiftsStream;
  bool isLoading = true;
  bool isSelected = false;
  String? selectedShiftId;

  @override
  void initState() {
    super.initState();
    fetchShifts();
    getShiftStream();
  }

  Future<void> getShiftStream() async {
    shiftsStream = ShiftHelper.getWeeklyShiftDataStream(
      context.getCompanyId(),
    );
  }

  /// Fetch the list of shifts from Firestore/DB
  Future<void> fetchShifts() async {
    try {
      shifts = await ShiftHelper.getAllShifts(
        companyId: context.getCompanyId(),
      );
    } catch (e) {
      debugPrint("Failed to load shifts: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 25,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: AlignmentGeometry.bottomRight,
          child: InkWell(
            onDoubleTap: () {
              //
              NavigatorHelper.navigateTo(
                context,
                Routes.AddNewShiftScreen,
                {},
              );
            },
            child: Container(
              height: 36,
              width: 84,
              margin: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                color: Hexify(
                  colorCode: '#5A5A5A',
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  "+ Shift",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        CustomStreamBuilder(
          stream: shiftsStream,
          builder: (context, snapshot) {
            final shiftsData = snapshot.data ?? [];
            if (shiftsData.isEmpty) {
              return Center(
                child: Text(
                  "No shifts available. Please add a new shift.",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              );
            }
            return CustomMasnoryGridView(
              children: shiftsData
                  .map((shift) => Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (selectedShiftId == shift.id) {
                                selectedShiftId = null;
                              } else {
                                selectedShiftId = shift.id;
                              }
                            });
                          },
                          onDoubleTap: () {
                            Provider.of<PopupProvider>(context, listen: false)
                                .pushPopupStack = Popup(
                              barrierDismissible: true,
                              id: 'new-shift-popup',
                              element: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                    child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.7,
                                  width:
                                      MediaQuery.of(context).size.width * 0.5,
                                  child: AddNewShift(
                                    shiftModel: shift,
                                  ),
                                )),
                              ),
                            );
                          },
                          child: ShiftCard(
                            isSelected: selectedShiftId == shift.id,
                            shiftModel: shift,
                          ),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
