import 'package:cladbe_hr_management/src/ui/widgets/CustomPopUpMenu.dart';
import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexify/hexify.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class HolidayCard extends StatefulWidget {
  final HolidayModel holiday;
  final bool isSelected;

  const HolidayCard({
    super.key,
    required this.holiday,
    required this.isSelected,
  });

  @override
  State<HolidayCard> createState() => _HolidayCardState();
}

class _HolidayCardState extends State<HolidayCard> {
  bool _isPopupOpen = false;
  void _setPopupOpen(bool isOpen) {
    setState(() {
      _isPopupOpen = isOpen;
      if (!isOpen) {
        // _handleOtherOptionsKey.currentState?._setHovered(false);
        setState(() {
          //
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 130,
      width: 424,
      padding: const EdgeInsets.only(left: 20, right: 15, top: 10, bottom: 10),
      decoration: BoxDecoration(
        gradient: Hexify(
          gradientType: HexifyGradientType.linearGradient,
          firstColor: '#1C1D23',
          secondColor: '#2C2D35',
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Hexify(colorCode: '#454545'),
          width: 1,
        ),
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: AppDefault.primaryColor.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.holiday.name.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _buildMoreOptionsButton()
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "${widget.holiday.totalOccassionsHolidays} in occasions",
            style: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.holiday.description.isEmpty
                        ? "----"
                        : widget.holiday.description,
                    style: GoogleFonts.poppins(
                      color: AppDefault.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  // Text(
                  //   "Duration",
                  //   style: GoogleFonts.poppins(
                  //     color: AppDefault.textGreySubHeadingColor,
                  //     fontSize: 11,
                  //   ),
                  // ),
                ],
              ),
              // Column(
              //   crossAxisAlignment: CrossAxisAlignment.start,
              //   children: [
              //     Text(
              //       "${shiftModel.getBreakHoursForDay(WeekDay.monday).toStringAsFixed(1)} Hrs",
              //       style: GoogleFonts.poppins(
              //         color: AppDefault.textColor,
              //         fontSize: 14,
              //         fontWeight: FontWeight.w600,
              //       ),
              //     ),
              //     Text(
              //       "Break Time",
              //       style: GoogleFonts.poppins(
              //         color: AppDefault.textGreySubHeadingColor,
              //         fontSize: 11,
              //       ),
              //     ),
              //   ],
              // ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMoreOptionsButton() {
    return Center(
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: PopupMenuButton(
          tooltip: '',
          splashRadius: 0.1,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          color: const Color(0xFF2C2D37),
          position: PopupMenuPosition.under,
          onOpened: () => _setPopupOpen(true),
          onCanceled: () => _setPopupOpen(false),
          onSelected: (value) => _handleMenuSelection(
            value: value,
            holidayId: widget.holiday.id,
          ),
          itemBuilder: (context) {
            return [
              PopupMenuItem(
                value: 0,
                child: Text(
                  "Delete",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            ];
          },
          child: Icon(
            Feather.more_vertical,
            color: Hexify(colorCode: "A2A2A2"),
            size: 14,
          ),
        ),
      ),
    );
  }

  void _handleMenuSelection({
    required int value,
    required String holidayId,
  }) {
    if (value == 0) {
      //
      HolidaysHelper.deleteHoliday(
          companyId: context.getCompanyId(), holidayId: holidayId);
    }
  }

  /// Avatar builder
  Widget _avatar(String url) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: CircleAvatar(
        radius: 15,
        backgroundImage: NetworkImage(url),
      ),
    );
  }
}
