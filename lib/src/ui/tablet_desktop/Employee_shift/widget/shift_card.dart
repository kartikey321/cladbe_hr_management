import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexify/hexify.dart';

class ShiftCard extends StatelessWidget {
  final WeeklyShiftModel shiftModel;

  const ShiftCard({super.key, required this.shiftModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 162,
      width: 424,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                shiftModel.shiftName,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppDefault.greenColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  shiftModel.isActive ? "Active" : "Inactive",
                  style: GoogleFonts.poppins(
                    color: AppDefault.greenColor,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "${shiftModel.totalWorkingDays} Days a Week",
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
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${shiftModel.getShiftHoursForDay(WeekDay.monday).toStringAsFixed(1)} Hrs",
                    style: GoogleFonts.poppins(
                      color: AppDefault.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Duration",
                    style: GoogleFonts.poppins(
                      color: AppDefault.textGreySubHeadingColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${shiftModel.getBreakHoursForDay(WeekDay.monday).toStringAsFixed(1)} Hrs",
                    style: GoogleFonts.poppins(
                      color: AppDefault.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Break Time",
                    style: GoogleFonts.poppins(
                      color: AppDefault.textGreySubHeadingColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _avatar("https://i.pravatar.cc/100?img=1"),
                  _avatar("https://i.pravatar.cc/100?img=2"),
                  _avatar("https://i.pravatar.cc/100?img=3"),
                  _avatar("https://i.pravatar.cc/100?img=4"),
                ],
              )
            ],
          )
        ],
      ),
    );
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
