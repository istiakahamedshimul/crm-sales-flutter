import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:real_estate_crm_sales/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const _pendingKey = 'pending_location_points';
const _enabledKey = 'location_tracking_enabled';
const _backgroundTaskUniqueName = 'active-location-periodic-capture';
const _backgroundTaskName = 'capture-active-location';

@pragma('vm:entry-point')
void locationTrackingCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != _backgroundTaskName) return true;

    DartPluginRegistrant.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final enabled = prefs.getBool(_enabledKey) ?? true;
    final token = prefs.getString('token') ?? '';
    if (!enabled || token.isEmpty) return true;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) return true;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always) {
        return true;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
      await _queueAndUpload(_point(position));
      return true;
    } catch (_) {
      // Periodic work will try again at its next system-scheduled run.
      return true;
    }
  });
}

class LocationTrackingService {
  StreamSubscription<Position>? _subscription;
  bool _starting = false;

  Future<void> configure() async {
    if (!Platform.isAndroid) return;
    await Workmanager().initialize(locationTrackingCallbackDispatcher);

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? true;
    final token = prefs.getString('token') ?? '';
    if (enabled && token.isNotEmpty) {
      await _scheduleBackgroundTracking();
    } else {
      await _cancelBackgroundTracking();
    }
  }

  Future<bool> loadEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getBool(_enabledKey) ?? true;
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) return local;
    try {
      final response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/locations/tracking-status'),
          headers: {
            'Authorization': 'Bearer $token'
          }).timeout(const Duration(seconds: 10));
      if (response.statusCode < 300) {
        final enabled = (jsonDecode(response.body)
                as Map<String, dynamic>)['enabled'] as bool? ??
            local;
        await prefs.setBool(_enabledKey, enabled);
        return enabled;
      }
    } catch (_) {}
    return local;
  }

  Future<bool> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (!enabled) {
      await stop();
      await _cancelBackgroundTracking();
    }
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) return false;
    try {
      final response = await http
          .put(Uri.parse('${AppConfig.apiBaseUrl}/locations/tracking-status'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token'
              },
              body: jsonEncode({'enabled': enabled}))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode >= 300) return false;
      if (enabled) {
        await _scheduleBackgroundTracking();
        unawaited(startWithPermission());
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startWithPermission() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_enabledKey) ?? true)) return false;
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
      if (Platform.isAndroid && permission == LocationPermission.whileInUse) {
        // Android grants foreground access before background access.
        permission = await Geolocator.requestPermission();
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
      _subscription =
          Geolocator.getPositionStream(locationSettings: settings).listen(
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
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 20));
      await _queueAndUpload(_point(position));
    } catch (_) {
      // The continuous stream remains active and will provide the next fix.
    }
  }

  Future<bool> get isRunning async => _subscription != null;

  Future<bool> get hasBackgroundPermission async =>
      !Platform.isAndroid ||
      await Geolocator.checkPermission() == LocationPermission.always;

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> stopAndUnschedule() async {
    await stop();
    await _cancelBackgroundTracking();
  }

  Future<void> _scheduleBackgroundTracking() async {
    if (!Platform.isAndroid) return;
    await Workmanager().registerPeriodicTask(
      _backgroundTaskUniqueName,
      _backgroundTaskName,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.not_required),
    );
  }

  Future<void> _cancelBackgroundTracking() async {
    if (!Platform.isAndroid) return;
    await Workmanager().cancelByUniqueName(_backgroundTaskUniqueName);
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
  final retained =
      pending.skip(pending.length > 500 ? pending.length - 500 : 0).toList();
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
