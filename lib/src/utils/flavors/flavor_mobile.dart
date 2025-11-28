import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/widgets.dart';

import '../../routes/route_config/route_names.dart';

class MobileFlavorType {
  static MapEntry<String, Widget Function(dynamic arguments)> _generateRoutes(
      String route,
      {String? flavorType,
      String? path}) {
    return MapEntry(route, (arg) {
      return RouteWidgetGenerator().getMobileWidget(
        route,
        arg,
        flavorType: flavorType,
        path: path,
      );
    });
  }

  static MobileFlavorTypeItem get ADMIN {
    var flavorType = 'ADMIN';
    var entries =
        <RouteData>[...Routes().routes].map((e) => _generateRoutes(e.name));
    return MobileFlavorTypeItem(
      name: flavorType,
      tabs: [
        MobileTabItem(
          name: 'Home',
          image: CustomAssetProvider(path: 'assets/bank.png', packageName: ''),
          route: Routes.DemoScreen.name,
        ),
      ],
      routes: Map.fromEntries(entries),
    );
  }

  static MobileFlavorTypeItem get STAGING {
    var flavorType = 'STAGING';
    var entries =
        <RouteData>[...Routes().routes].map((e) => _generateRoutes(e.name));
    return MobileFlavorTypeItem(
      name: flavorType,
      tabs: [
        MobileTabItem(
          name: 'Home',
          image: CustomAssetProvider(path: 'assets/bank.png', packageName: ''),
          route: Routes.DemoScreen.name,
        ),
      ],
      routes: Map.fromEntries(entries),
    );
  }

  static MobileFlavorTypeItem get PRODUCTION {
    var flavorType = 'PRODUCTION';
    var entries =
        <RouteData>[...Routes().routes].map((e) => _generateRoutes(e.name));
    return MobileFlavorTypeItem(
      name: flavorType,
      tabs: [
        MobileTabItem(
          name: 'Home',
          image: CustomAssetProvider(path: 'assets/bank.png', packageName: ''),
          route: Routes.DemoScreen.name,
        ),
      ],
      routes: Map.fromEntries(entries),
    );
  }

  static List<MobileFlavorTypeItem> allTypes = [ADMIN, STAGING, PRODUCTION];
}
