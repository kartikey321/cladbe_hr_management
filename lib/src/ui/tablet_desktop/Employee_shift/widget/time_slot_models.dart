import 'package:flutter/material.dart';

/// Model for shift time slot with text controllers
class ShiftTimeSlot {
  TextEditingController startController = TextEditingController();
  TextEditingController endController = TextEditingController();

  void dispose() {
    startController.dispose();
    endController.dispose();
  }
}

/// Model for break time slot with text controllers
class BreakTimeSlot {
  TextEditingController startController = TextEditingController();
  TextEditingController endController = TextEditingController();

  void dispose() {
    startController.dispose();
    endController.dispose();
  }
}
