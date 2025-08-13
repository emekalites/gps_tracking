import 'package:fl_location/fl_location.dart';
import 'package:get/get.dart';
import 'package:gps_tracker/services/database_service.dart';
import 'package:gps_tracker/services/location_service.dart';

class LocationController extends GetxController {
  Rx<Location?> location = Rx<Location?>(null);
  List<Map<String, dynamic>> storedLocations = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initDatabase();
    LocationService.instance.addLocationChangedCallback(_onLocationChanged);
    _startLocationService();
  }

  Future<void> _initDatabase() async {
    storedLocations.assignAll(DatabaseService.instance.getAllLocations());
  }

  void _onLocationChanged(Location loc) {
    location.value = loc;

    // Save to DB
    DatabaseService.instance.insertLocation(
      latitude: loc.latitude,
      longitude: loc.longitude,
      accuracy: loc.accuracy,
      altitude: loc.altitude,
      heading: loc.heading,
      speed: loc.speed,
      timestamp: loc.timestamp.toString(),
    );

    // Update in-memory list
    storedLocations.assignAll(DatabaseService.instance.getAllLocations());
  }

  void _startLocationService() async {
    try {
      if (await LocationService.instance.isRunningService) return;
      await LocationService.instance.start();
    } catch (e) {
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
    LocationService.instance.removeLocationChangedCallback(_onLocationChanged);
    DatabaseService.instance.close();
    super.onClose();
  }
}
