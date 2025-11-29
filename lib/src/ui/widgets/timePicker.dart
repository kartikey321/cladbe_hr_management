import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as material show TimeOfDay;

class CustomTimepicker {
  static Future<material.TimeOfDay?> showThemedTimePicker(
      BuildContext context) async {
    return await showTimePicker(
      context: context,
      initialTime: material.TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppDefault.popUpAppBar,
              dayPeriodColor: AppDefault.primaryColor, // background of AM/PM
              dayPeriodTextColor: Colors.white, // text: AM / PM

              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              dayPeriodBorderSide: const BorderSide(
                color: Colors.white,
                width: 1,
              ),
            ),
            colorScheme: ColorScheme.dark(
              primary: AppDefault.popUpAppBar,
              onPrimary: AppDefault.primaryColor,
              surface: AppDefault.filterBarColor,
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppDefault.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
