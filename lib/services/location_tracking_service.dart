import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:real_estate_crm_sales/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pendingKey = 'pending_location_points';

class LocationTrackingService {
  StreamSubscription<Position>? _subscription;
  bool _starting = false;

  Future<void> configure() async {}

  Future<bool> startWithPermission() async {
    if (_starting) return false;
    if (_subscription != null) return true;
    _starting = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        // Let Android finish the permission activity before starting its
        // foreground location service.
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      final settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
        intervalDuration: const Duration(seconds: 30),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Field location active',
          notificationText: 'Your work route is being recorded securely',
          enableWakeLock: true,
        ),
      );

      // Do not make app startup depend on receiving a satellite fix.
      unawaited(_captureInitial());
      _subscription = Geolocator.getPositionStream(locationSettings: settings)
          .listen(
        (position) => unawaited(_queueAndUpload(_point(position))),
        onError: (_) {},
        cancelOnError: false,
      );
      return true;
    } catch (_) {
      await _subscription?.cancel();
      _subscription = null;
      return false;
    } finally {
      _starting = false;
    }
  }

  Future<void> _captureInitial() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 20));
      await _queueAndUpload(_point(position));
    } catch (_) {
      // The continuous stream remains active and will provide the next fix.
    }
  }

  Future<bool> get isRunning async => _subscription != null;

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> openSettings() => Geolocator.openAppSettings();
}

Map<String, dynamic> _point(Position position) => {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracyMeters': position.accuracy,
      'speedMetersPerSecond': position.speed,
      'heading': position.heading,
      'altitudeMeters': position.altitude,
      'isMocked': position.isMocked,
      'recordedAtUtc': position.timestamp.toUtc().toIso8601String(),
    };

Future<void> _queueAndUpload(Map<String, dynamic> point) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final pending = (prefs.getStringList(_pendingKey) ?? [])
      .map((value) => jsonDecode(value) as Map<String, dynamic>)
      .toList()
    ..add(point);
  final retained = pending
      .skip(pending.length > 500 ? pending.length - 500 : 0)
      .toList();
  await prefs.setStringList(_pendingKey, retained.map(jsonEncode).toList());

  final token = prefs.getString('token') ?? '';
  if (token.isEmpty) return;
  try {
    final response = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/locations/batch'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'points': retained}),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 300) await prefs.remove(_pendingKey);
  } catch (_) {
    // Retained locally and retried with the next GPS point.
  }
}

final locationTrackingService = LocationTrackingService();
