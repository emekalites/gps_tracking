import 'package:flutter/material.dart';
import 'package:gps_tracker/config/routes.dart';
import 'package:gps_tracker/services/location_service.dart';
import 'package:gps_tracker/views/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocationService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Tracker',
      debugShowCheckedModeBanner: false,
      routes: {Routes.main: (_) => const MainPage()},
      initialRoute: Routes.main,
    );
  }
}
