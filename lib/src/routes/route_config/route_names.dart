import 'package:cladbe_shared/cladbe_shared.dart';
import '../route_data/hrscreen_route_data.dart';
import '../route_data/attendancedashboardscreen_route_data.dart';

import '../route_data/demoscreen_route_data.dart';

class Routes extends BaseRoutes {
  static const RouteData AttendanceDashboardScreen =
      AttendanceDashboardScreenRouteData(name: '/attendance-dashboard-screen');

  static const RouteData HrScreen = HrScreenRouteData(name: '/hr-screen');

  static Routes? _instance;

  static const RouteData DemoScreen = DemoScreenRouteData(name: '/demo-screen');
  Routes._internal()
      : super.protected(initialRoutes: [
          Routes.HrScreen,
          Routes.AttendanceDashboardScreen,
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
