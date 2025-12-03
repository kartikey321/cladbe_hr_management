import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gradient_container.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData? icon;
  final VoidCallback? onTap; // NEW
  const StatCard(
      {super.key,
      required this.title,
      required this.count,
      this.icon,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> attendanceStatusColors = {
      "present": const Color(0xFF34C759), // Green
      "checked out": const Color(0xFF5E7CE2), // Blue
      "absent": const Color(0xFFFF3B30), // Red
      "late": const Color(0xFFFFA500), // Orange
      "partial shift": const Color(0xFFAF52DE), // Purple
      "on break": const Color(0xFFFFD60A), // Yellow
      "not checked in yet": const Color(0xFF8E8E93), // Gray
      "-": const Color(0xFF8E8E93),
    };
    Color getStatusColor(String status) {
      return attendanceStatusColors[status.toLowerCase()] ??
          const Color(0xFF8E8E93); // default gray
    }

    return GestureDetector(
      onTap: onTap, // enabled
      child: GradientContainer(
        width: 261.52,
        height: 108.45,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF8B8D97),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2D35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: getStatusColor(title),
                      size: 20,
                    ),
                  ),
              ],
            ),
            Row(
              spacing: 7,
              children: [
                Container(
                  height: 8,
                  width: 8,
                  decoration: BoxDecoration(
                    color: getStatusColor(title),
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  count,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
