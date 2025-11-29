import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';

import '../../routes/route_config/route_names.dart';

class FlavorType {
  static MapEntry<String, Widget Function(dynamic arguments)> _generateRoutes(
      String route,
      {String? flavorType,
      String? path}) {
    return MapEntry(route, (arg) {
      return RouteWidgetGenerator().getWidget(
        route,
        arg,
        flavorType: flavorType,
        path: path,
      );
    });
  }

  static FlavorTypeItem get ADMIN {
    var flavorType = 'ADMIN';
    var entries =
        <RouteData>[...Routes().routes].map((e) => _generateRoutes(e.name));
    return FlavorTypeItem(
      name: flavorType,
      tabs: [
        LeftBarElement(
          name: 'Project',
          image: CustomAssetProvider(
              path: 'assets/bank.png', packageName: 'cladbe_hr_management'),
          routes: Map.fromEntries(entries),
          elements: {},
        )
      ],
    );
  }

  static FlavorTypeItem get STAGING {
    var flavorType = 'STAGING';
    var entries =
        <RouteData>[...Routes().routes].map((e) => _generateRoutes(e.name));
    return FlavorTypeItem(
      name: flavorType,
      tabs: [
        LeftBarElement(
          name: 'Project',
          image: CustomAssetProvider(
              path: 'assets/bank.png', packageName: 'cladbe_hr_management'),
          routes: Map.fromEntries(entries),
          elements: {},
        )
      ],
    );
  }

  static FlavorTypeItem get PRODUCTION {
    var flavorType = 'PRODUCTION';
    var entries =
        <RouteData>[...Routes().routes].map((e) => _generateRoutes(e.name));
    return FlavorTypeItem(
      name: flavorType,
      tabs: [
        LeftBarElement(
          name: 'Project',
          image: CustomAssetProvider(
              path: 'assets/bank.png', packageName: 'cladbe_hr_management'),
          routes: Map.fromEntries(entries),
          elements: {},
        )
      ],
    );
  }

  static List<FlavorTypeItem> allTypes = [ADMIN, STAGING, PRODUCTION];
}
