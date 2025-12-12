import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DropDownSuggestionTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool isRequired;
  final FormFieldValidator<String>? validator;
  final Function(String)? onChanged;
  final Function(String)? onSelected;
  final List<String>? dropdownItems;
  final IconData? dropdownPrefixIcon;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final bool enabled;
  final FocusNode? focusNode;
  final EdgeInsets? padding;
  final int? maxLength;
  final TextInputType? keyboardType;
  final bool showBorder;

  const DropDownSuggestionTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.isRequired = false,
    this.validator,
    this.onChanged,
    this.onSelected,
    this.dropdownItems,
    this.showBorder = true,
    this.dropdownPrefixIcon,
    this.style,
    this.hintStyle,
    this.enabled = true,
    this.focusNode,
    this.padding,
    this.maxLength,
    this.keyboardType,
  });

  @override
  State<DropDownSuggestionTextField> createState() =>
      _DropDownSuggestionTextFieldState();
}

class _DropDownSuggestionTextFieldState
    extends State<DropDownSuggestionTextField> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isShowingDropdown = false;

  /// Use dropdownItems for all suggestions
  List<String> get _allItems {
    final items = widget.dropdownItems ?? [];
    return items.toSet().toList()..sort();
  }

  List<String> _getFilteredSuggestions(String query) {
    if (query.trim().isEmpty) return _allItems;

    return _allItems
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .take(8)
        .toList();
  }

  void _showDropdown() {
    if (!widget.enabled) return;
    if (_isShowingDropdown) return;

    final suggestions = _getFilteredSuggestions(_controller.text);
    if (suggestions.isEmpty) return;

    _isShowingDropdown = true;
    _overlayEntry = _createOverlayEntry(suggestions);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    if (!widget.enabled) return;
    if (!_isShowingDropdown) return;

    _isShowingDropdown = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateDropdown() {
    if (!widget.enabled) return;
    if (!_isShowingDropdown) return;

    final suggestions = _getFilteredSuggestions(_controller.text);
    if (suggestions.isEmpty) {
      _hideDropdown();
      return;
    }

    _overlayEntry?.remove();
    _overlayEntry = _createOverlayEntry(suggestions);
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _createOverlayEntry(List<String> suggestions) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height - 20),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(6.0),
            color: const Color(0xFF2C2D37),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: suggestions.map((item) {
                    return InkWell(
                      onTap: () {
                        _controller.text = item;
                        widget.onChanged?.call(item);
                        _hideDropdown();
                        _focusNode.unfocus();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.1),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.dropdownPrefixIcon ?? Icons.list,
                              size: 16,
                              color: AppDefault.violetColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTextChanged(String value) {
    // THIS LINE WAS MISSING — NOW IT WORKS!
    widget.onChanged?.call(value);

    if (_focusNode.hasFocus) {
      _updateDropdown();
      if (!_isShowingDropdown && value.isNotEmpty) {
        _showDropdown();
      }
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _updateDropdown();
      if (!_isShowingDropdown) {
        _showDropdown();
      }
    } else {
      Future.delayed(const Duration(milliseconds: 150), () {
        _hideDropdown();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(() => _onTextChanged(_controller.text));
  }

  @override
  void dispose() {
    _hideDropdown();
    _focusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) _focusNode.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(left: 5.0, bottom: 2, right: 5.0),
            child: RichText(
              text: TextSpan(
                text: widget.label!,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppDefault.textColor,
                ),
                children: widget.isRequired
                    ? [
                        TextSpan(
                          text: ' *',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                      ]
                    : [],
              ),
            ),
          ),
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            decoration: BoxDecoration(
              gradient: widget.showBorder
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF37374E).withOpacity(0.19),
                        const Color(0xFF555572).withOpacity(0.19),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: CustomTextFormField(
              controller: _controller,
              disableBorder: true,
              focusNode: _focusNode,
              enabled: widget.enabled,
              hint: widget.hint ?? 'Select an option',
              hintStyle: widget.hintStyle ??
                  GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFC4C4C4),
                  ),
              style: widget.style ??
                  GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                  ),
              // REMOVE THE 'value:' CALLBACK — IT'S DUPLICATE!
              maxLength: widget.maxLength,
              keyboardType: widget.keyboardType ?? TextInputType.text,
              padding: widget.padding ?? const EdgeInsets.all(18.3),
              radiusGeometry: BorderRadius.circular(6),
              validator: widget.validator,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              suffix: GestureDetector(
                onTap: hasText
                    ? () {
                        if (!widget.enabled) return;
                        _controller.clear();
                        widget.onChanged?.call(""); // ← Notify clear
                        _updateDropdown();
                      }
                    : null,
                child: Icon(
                  hasText ? Icons.clear : Icons.arrow_drop_down,
                  color: AppDefault.violetColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
