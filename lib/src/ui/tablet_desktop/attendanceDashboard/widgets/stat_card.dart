import 'dart:math';

import 'package:flutter/material.dart';
import 'gradient_container.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData? icon;

  const StatCard({
    super.key,
    required this.title,
    required this.count,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    List<Color> dotColors = [
      const Color(0xFF7578CD),
      const Color(0xFF76FA61),
    ];
    Color generator(int index) {
      return dotColors[index % dotColors.length];
    }

    return GradientContainer(
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
                style: const TextStyle(
                  color: Color(0xFF8B8D97),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
                    color: const Color(0xFF8B8D97),
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
                  color: generator(Random().nextInt(2)),
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                count,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
