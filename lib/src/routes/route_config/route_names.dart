import 'package:cladbe_shared/cladbe_shared.dart';

import '../route_data/demoscreen_route_data.dart';


class Routes extends BaseRoutes {
  static Routes? _instance;
  

  static const RouteData DemoScreen = DemoScreenRouteData(name: '/demo-screen');
  Routes._internal()
      : super.protected(initialRoutes: [
          DemoScreen
        ]);

  // Singleton factory constructor
  factory Routes() {
    _instance ??= Routes._internal();
    return _instance!;
  }

  // Static getter to access the singleton instance
  static Routes get instance {
    if (_instance == null) {
      throw StateError('Routes has not been initialized. Call Routes() first.');
    }
    return _instance!;
  }
}