import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gps_tracker/services/database_service.dart';
import 'package:gps_tracker/services/location_service.dart';
import 'package:gps_tracker/views/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.init();
  LocationService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(title: 'GPS Tracker', debugShowCheckedModeBanner: false, home: MainPage());
  }
}
