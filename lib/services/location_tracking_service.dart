import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:real_estate_crm_sales/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pendingKey = 'pending_location_points';

@pragma('vm:entry-point')
Future<void> locationServiceEntry(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(title: 'Field location active', content: 'Your work route is being recorded securely');
  }
  service.on('stop').listen((_) => service.stopSelf());
  final settings = AndroidSettings(
    accuracy: LocationAccuracy.high, distanceFilter: 25,
    intervalDuration: const Duration(seconds: 30),
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationTitle: 'Field location active', notificationText: 'Your work route is being recorded securely', enableWakeLock: true),
  );
  Geolocator.getPositionStream(locationSettings: settings).listen((position) async {
    final point = <String, dynamic>{
      'latitude': position.latitude, 'longitude': position.longitude, 'accuracyMeters': position.accuracy,
      'speedMetersPerSecond': position.speed, 'heading': position.heading, 'altitudeMeters': position.altitude,
      'isMocked': position.isMocked, 'recordedAtUtc': position.timestamp.toUtc().toIso8601String(),
    };
    await _queueAndUpload(point);
    service.invoke('location', point);
  });
}

Future<void> _queueAndUpload(Map<String, dynamic> point) async {
  final prefs = await SharedPreferences.getInstance();
  final pending = (prefs.getStringList(_pendingKey) ?? []).map((x) => jsonDecode(x) as Map<String, dynamic>).toList()..add(point);
  final retained = pending.skip(pending.length > 500 ? pending.length - 500 : 0).toList();
  await prefs.setStringList(_pendingKey, retained.map(jsonEncode).toList());
  final token = prefs.getString('token') ?? '';
  if (token.isEmpty) return;
  try {
    final response = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/locations/batch'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'points': retained})).timeout(const Duration(seconds: 15));
    if (response.statusCode < 300) await prefs.remove(_pendingKey);
  } catch (_) { /* The queue is retried with the next GPS point. */ }
}

class LocationTrackingService {
  final _service = FlutterBackgroundService();
  Future<void> configure() => _service.configure(
    iosConfiguration: IosConfiguration(autoStart: false, onForeground: locationServiceEntry),
    androidConfiguration: AndroidConfiguration(onStart: locationServiceEntry, autoStart: false, isForegroundMode: true,
      notificationChannelId: 'crm_field_location', initialNotificationTitle: 'Field location active',
      initialNotificationContent: 'Starting secure route recording…', foregroundServiceNotificationId: 4107));
  Future<bool> startWithPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return false;
    if (!await _service.isRunning()) await _service.startService();
    return true;
  }
  Future<bool> get isRunning => _service.isRunning();
  void stop() => _service.invoke('stop');
  Future<void> openSettings() => Geolocator.openAppSettings();
}

final locationTrackingService = LocationTrackingService();
