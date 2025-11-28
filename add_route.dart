import 'dart:io';
import 'package:cladbe_shared/route_automation.dart';

void main(List<String> arguments) {
  print('Usage: dart add_route.dart <routeName> <routeValue>');
  if (arguments.length != 2) {
    print('Usage: dart add_route.dart <routeName> <routeValue>');
    return;
  }

  final routeName = arguments[0];
  final routeValue = arguments[1];

  AddRoute().executeRouteAutomation(routeName, routeValue);
}
