import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomPopupMenuItemData {
  final int id;
  final Widget child;
  // final PermissionAction? permission;
  final bool hideIfNoAccess;

  const CustomPopupMenuItemData({
    required this.id,
    required this.child,
    // this.permission,
    this.hideIfNoAccess = false,
  });
}

class CustomPopupMenuButton<T extends int> extends StatelessWidget {
  final List<CustomPopupMenuItemData> items;
  final Widget? icon;
  final T? initialValue;
  final String? tooltip;
  final double? splashRadius;
  final Color? color;
  final ShapeBorder? shape;
  final PopupMenuPosition position;
  final AnimationStyle? popUpAnimationStyle;
  final void Function(T value) onSelected;
  final VoidCallback? onCanceled;
  final T? Function()? onOpened;

  const CustomPopupMenuButton({
    super.key,
    required this.items,
    required this.onSelected,
    this.icon,
    this.initialValue,
    this.tooltip,
    this.splashRadius,
    this.color,
    this.shape,
    this.position = PopupMenuPosition.over,
    this.popUpAnimationStyle,
    this.onCanceled,
    this.onOpened,
  });

  // bool _hasPermission(BuildContext context, CustomPopupMenuItemData item) {
  //   final perm = item.permission;
  //   if (perm == null) return true;
  //   final access = context.read<EmployeeAccessUtils>();
  //   return access.hasAccess(
  //     moduleKey: perm.moduleKey,
  //     submoduleKey: perm.submoduleKey,
  //     accessKey: perm.accessKey,
  //     projectId: perm.projectId,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    // Compute permissions once per build for consistency across filter and itemBuilder
    final Map<int, bool> itemPermissions = {};
    // for (final item in items) {
    //   itemPermissions[item.id] = _hasPermission(context, item);
    // }

    final allowedItems = items.where((item) {
      final ok = itemPermissions[item.id]!;
      if (!ok && item.hideIfNoAccess) return false;
      return true;
    }).toList();

    if (allowedItems.isEmpty) {
      return const SizedBox.shrink(); // no menu if nothing to show
    }

    return PopupMenuButton<T>(
      icon: icon,
      tooltip: tooltip ?? '',
      splashRadius: splashRadius ?? 24.0, // Use a more standard radius
      shape: shape,
      position: position,
      color: color,
      initialValue: initialValue,
      padding: const EdgeInsetsGeometry.all(0),
      menuPadding: const EdgeInsetsGeometry.all(0),
      popUpAnimationStyle: popUpAnimationStyle,
      onOpened: onOpened,
      onCanceled: onCanceled,
      onSelected: onSelected,
      itemBuilder: (BuildContext menuContext) {
        // Use pre-computed permissions for consistency (ignore menuContext differences)
        return allowedItems.map((item) {
          final allowed = itemPermissions[item.id]!;
          return PopupMenuItem<T>(
            value: item.id as T,
            enabled: allowed,
            child: Opacity(
              opacity: allowed ? 1.0 : 0.4,
              child: item.child,
            ),
          );
        }).toList();
      },
    );
  }
}
