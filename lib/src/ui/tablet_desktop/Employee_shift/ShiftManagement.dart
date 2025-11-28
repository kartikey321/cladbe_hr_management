import 'package:cladbe_hr_management/src/ui/tablet_desktop/Employee_shift/widget/add_New_shift.dart';
import 'package:cladbe_hr_management/src/ui/tablet_desktop/Employee_shift/widget/shift_card.dart';
import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexify/hexify.dart';
import 'package:provider/provider.dart';

class ShiftManagement extends StatefulWidget {
  const ShiftManagement({super.key});

  @override
  State<ShiftManagement> createState() => _ShiftManagementState();
}

class _ShiftManagementState extends State<ShiftManagement> {
  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 25,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: AlignmentGeometry.bottomRight,
          child: InkWell(
            onTap: () {
              //
              Provider.of<PopupProvider>(context, listen: false)
                  .pushPopupStack = Popup(
                id: 'new-shift-popup',
                element: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: AddNewShift()),
                ),
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
        const ShiftCard()
      ],
    );
  }
}
