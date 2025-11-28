import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:flutter/material.dart';
import '../ui/mobile/demo_screen.dart';
import '../ui/tablet_desktop/demo_screen.dart';
import 'route_config/route_names.dart';

class CustomRouteWidgetGenerator implements RouteWidgetGeneratorBase {
  @override
  Map<String, RouteConfig> routeMap( ) => {
        // 'routeA': _RouteConfig(
        //   defaultWidget: DefaultWidgetForRouteA(),
        //   pathOverrides: {
        //     '/path1': SpecificWidgetForPath1(),
        //     '/path2': SpecificWidgetForPath2(),
        //   },
        //   flavorOverrides: {
        //     'flavor1': SpecificWidgetForFlavor1(),
        //     'flavor2': SpecificWidgetForFlavor2(),
        //   },
        //   pathFlavorOverrides: {
        //     '/path1': {
        //       'flavor1': SpecificWidgetForPath1Flavor1(),
        //       'flavor2': SpecificWidgetForPath1Flavor2(),
        //     },
        //   },
        // ),

        Routes.DemoScreen.name: RouteConfig(
          defaultWidget: (arguments) {
            return const DemoScreen();
          },
        ),

        // Additional routes can be added here
      };

  @override
  Map<String, RouteConfig> mobileRouteMap() {
    return {
      Routes.DemoScreen.name: RouteConfig(
        defaultWidget: (arguments) {
          return const MobileDemoScreen();
        },
      ),
    };
  }

  @override
  Widget globalDefaultWidget() => Container();
}
