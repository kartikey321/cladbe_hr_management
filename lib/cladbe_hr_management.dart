import 'package:cladbe_shared/cladbe_shared.dart';

import 'src/routes/route_config/route_names.dart';
import 'src/routes/route_widget_generator.dart';

List<RouteData> exportRoutes = Routes().publicRoutes;
RouteWidgetGeneratorBase get generator => CustomRouteWidgetGenerator();
