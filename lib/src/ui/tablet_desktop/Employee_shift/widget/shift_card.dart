import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexify/hexify.dart';

class ShiftCard extends StatelessWidget {
  const ShiftCard({super.key});

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
          /// TOP ROW — Title + Active Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Shift Name",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              /// ACTIVE BADGE
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppDefault.greenColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Active",
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

          /// SUBTITLE — Days
          Text(
            "5 Days",
            style: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 10),

          /// DIVIDER LINE
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// Duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "9 Hours",
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

              /// Break Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "1 Hour",
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

              /// CIRCLE AVATARS (example images)
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
      padding: const EdgeInsets.only(left: 6),
      child: CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(url),
      ),
    );
  }
}
