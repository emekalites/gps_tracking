// lib/services/location_service_handler.dart
import 'dart:async';
import 'dart:convert';

import 'package:fl_location/fl_location.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:gps_tracker/services/database_service.dart';
import 'package:http/http.dart' as http;

/// NOTE: Make sure DatabaseService.init() is called in the background isolate.
///       If path_provider fails inside the background isolate, get dbPath in
///       main(), then pass it via FlutterForegroundTask.startService task data
///       and call DatabaseService.instance.init(dbPath: ...) here.
@pragma('vm:entry-point')
void startLocationService() {
  FlutterForegroundTask.setTaskHandler(LocationServiceHandler());
}

class LocationServiceHandler extends TaskHandler {
  StreamSubscription<Location>? _streamSubscription;
  Timer? _syncTimer;

  // config
  final Duration syncInterval = const Duration(minutes: 5);
  final String endpoint = 'http://172.18.0.51:4000/location';
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    // 'Authorization': 'Bearer ...' // add if needed
  };

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // If you passed initial task data (e.g., DB path), fetch it here:
    // final data = await FlutterForegroundTask.getLatestTaskData();
    // final String? dbPath = data as String?;
    // await DatabaseService.instance.init(dbPath: dbPath);

    // Try normal init (path_provider), works in most cases.
    await DatabaseService.instance.init();

    // Start listening for location updates
    _streamSubscription = FlLocation.getLocationStream().listen(
      (location) async {
        // Insert into DB (durable)
        DatabaseService.instance.insertLocation(
          latitude: location.latitude,
          longitude: location.longitude,
          accuracy: location.accuracy,
          altitude: location.altitude,
          heading: location.heading,
          speed: location.speed,
          timestamp: location.timestamp.toString(),
        );

        // Update notification content
        final String text =
            'lat: ${location.latitude.toStringAsFixed(6)}, lon: ${location.longitude.toStringAsFixed(6)}';
        FlutterForegroundTask.updateService(notificationText: text);

        // Send to main isolate (so UI updates)
        final String locationJson = jsonEncode(location.toJson());
        FlutterForegroundTask.sendDataToMain(locationJson);

        // Attempt an immediate upload (one point)
        await _uploadOnePointIfAny();
      },
      onError: (e, s) {
        // optionally log
      },
    );

    // Periodic sync every 5 minutes to retry uploads if any remain
    _syncTimer = Timer.periodic(syncInterval, (_) async {
      await _uploadOnePointIfAny();
    });
  }

  /// Upload exactly one unsent row (oldest). If upload succeeds, mark as sent.
  Future<void> _uploadOnePointIfAny() async {
    try {
      final row = DatabaseService.instance.getOneUnsentLocation();
      if (row == null) return;

      // Build payload - change to match your server contract
      final payload = jsonEncode({
        'latitude': row['latitude'],
        'longitude': row['longitude'],
        'accuracy': row['accuracy'],
        'altitude': row['altitude'],
        'heading': row['heading'],
        'speed': row['speed'],
        'timestamp': row['timestamp'],
        'local_id': row['id'], // optional: send local id so server can echo it back
      });

      // Try POST (with a timeout)
      final response = await http
          .post(Uri.parse(endpoint), headers: headers, body: payload)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Successful — mark this local row as sent.
        DatabaseService.instance.markLocationAsSent(row['id'] as int);
      } else {
        // server responded but with error — leave row for retry later
        // you could parse response.body to decide partial/other behavior
      }
    } catch (e) {
      // network error / timeout / other — we'll retry on next timer or on next location update
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // not used
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTerminated) async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;

    _syncTimer?.cancel();
    _syncTimer = null;

    // close DB if desired — optional
    DatabaseService.instance.close();
  }
}
