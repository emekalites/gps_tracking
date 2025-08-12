import 'package:fl_location/fl_location.dart';
import 'package:flutter/widgets.dart';
import 'package:gps_tracker/controllers/base_controller.dart';
import 'package:gps_tracker/services/location_service.dart';
import 'package:gps_tracker/utils/error_handler_mixin.dart';

class MainPageController extends BaseController with ErrorHandlerMixin {
  final ValueNotifier<Location?> locationListenable = ValueNotifier(null);

  void _startLocationService() async {
    try {
      // already started
      if (await LocationService.instance.isRunningService) {
        return;
      }

      LocationService.instance.start();
    } catch (e, s) {
      handleError(e, s);
    }
  }

  void _onLocationChanged(Location location) {
    locationListenable.value = location;
  }

  @override
  void attach(State state) {
    super.attach(state);
    LocationService.instance.addLocationChangedCallback(_onLocationChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLocationService();
    });
  }

  @override
  void dispose() {
    LocationService.instance.removeLocationChangedCallback(_onLocationChanged);
    locationListenable.dispose();
    super.dispose();
  }
}
