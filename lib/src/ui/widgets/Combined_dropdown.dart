import 'package:cladbe_hr_management/src/ui/widgets/dropdownTextfield.dart';
import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';

class CombinedDropdownField extends StatelessWidget {
  final String leftLabel;
  final List<String> leftItems;
  final MultiSelectController leftController;
  final Function(List<String>)? onLeftSelected;

  /// RIGHT SIDE
  final bool useSuggestionField;
  final String rightLabel;
  final TextEditingController? rightTextController;
  final MultiSelectController? rightDropdownController;
  final List<String>? rightItems;
  final Function(String)? onRightSelected;
  final Function(String)? onRightChanged;

  const CombinedDropdownField({
    super.key,
    required this.leftLabel,
    required this.leftItems,
    required this.leftController,
    this.onLeftSelected,
    required this.useSuggestionField,
    required this.rightLabel,
    required this.rightTextController,
    this.rightDropdownController,
    this.rightItems,
    this.onRightSelected,
    this.onRightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF37374E).withOpacity(0.19),
            const Color(0xFF555572).withOpacity(0.19),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5A618D), width: 1),
      ),
      child: Row(
        children: [
          /// -------- LEFT SIDE DROPDOWN --------
          Expanded(
            flex: 2,
            child: DropdownTextField(
              dropdown: true,
              dropdownItems: leftItems,
              dropdownEnabled: true,
              dropdownController: leftController,
              selectedDropdownItems:
                  leftController.selectedOptions.map((e) => e.label).toList(),
              onOptionSelected: onLeftSelected,
              name: null,
              textFieldGradient: null,
              disableBorder: true,
              showClearIcon: false,
              textFieldPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),

          // / -------- VERTICAL SEPARATOR --------
          Container(
            width: 1,
            color: AppDefault.primaryColor,
          ),

          /// -------- RIGHT SIDE --------
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: useSuggestionField
                  ? DropDownSuggestionTextField(
                      controller: rightTextController,
                      hint: rightLabel,
                      dropdownItems: rightItems,
                      showBorder: false,
                      onChanged: onRightChanged,
                      onSelected: onRightSelected,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                    )
                  : DropdownTextField(
                      dropdown: true,
                      dropdownItems: rightItems,
                      dropdownController: rightDropdownController,
                      selectedDropdownItems: rightDropdownController != null
                          ? rightDropdownController!.selectedOptions
                              .map((e) => e.label)
                              .toList()
                          : [],
                      onOptionSelected: (values) {
                        if (values.isNotEmpty && onRightSelected != null) {
                          onRightSelected!(values.first);
                        }
                      },
                      name: null,
                      textFieldGradient: null,
                      disableBorder: true,
                      showClearIcon: false,
                      textFieldPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
