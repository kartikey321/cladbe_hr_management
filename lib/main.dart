import 'dart:convert';

import 'package:cladbe_shared/cladbe_shared.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/routes/route_config/route_names.dart';
import 'src/routes/route_widget_generator.dart';
import 'src/utils/flavors/flavor_mobile.dart';
import 'src/utils/flavors/flavors.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding is initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SharedPreferences preferences = await SharedPreferences.getInstance();

  final data = message.data;
  String deepLink = 'https://admin.cladbe.com/lead';

// Retrieve existing caller data from SharedPreferences
  String? sharedData = preferences.getString('callerData');
  Map<String, String> callerData = sharedData != null
      ? Map<String, String>.from(jsonDecode(sharedData))
      : {};

// Populate the map with new data
  callerData['callerName'] = data['clientName'] ?? '';
  callerData['callerNumber'] = data['clientNumber'] ?? '';
  callerData['triggerType'] = data['triggerType'] ?? '';
  callerData['leadStatus'] = data['leadStatus'] ?? '';
  callerData['leadSubStatus'] = data['leadSubStatus'] ?? '';
  callerData['companyId'] = data['companyId'] ?? 'A';
  callerData['baseId'] = data['baseId'] ?? '';

  print("Background message data: $callerData");

// Store the updated map in SharedPreferences
  await preferences.setString('callerData', jsonEncode(callerData));

// Send data to the overlay window
  await FlutterOverlayWindow.shareData(callerData);

// Start the overlay
  await startOverLay(callerData);
}

// Overlay entry point
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  String flavor = const String.fromEnvironment('FLAVOR', defaultValue: "");
  GenericFlavorConfig.init(
      GenericFlavorType: GenericFlavorType.allTypes
              .containsWithCondition((e) => e.name == flavor) ??
          GenericFlavorType.ADMIN);
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ChangeNotifierProvider(
        create: (context) => AppUtil(),
        child: IncomingCallPopup(
          firebaseMessagingBackgroundHandler: (message) async =>
              firebaseMessagingBackgroundHandler(message),
        )), // Show IncomingCallPopup widget in overlay
  ));
}

void main() async {
  AppMain appMain = AppMain();
  if (PlatformUtil.isMobile()) {
    await appMain.initMobileApp(
      firebaseMessagingBackgroundHandler: firebaseMessagingBackgroundHandler,
      flavors: MobileFlavorType.allTypes,
      defaultFlavor: MobileFlavorType.ADMIN,
      routes: Routes().routes,
      providers: [],
      routeWidgetGeneratorBase: CustomRouteWidgetGenerator(),
    );
  } else {
    await appMain.initDesktopApp(
        flavors: FlavorType.allTypes,
        defaultFlavor: FlavorType.ADMIN,
        providers: [],
        routes: Routes().routes,
        routeWidgetGeneratorBase: CustomRouteWidgetGenerator());
  }
}
