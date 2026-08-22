import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// The single integration point for OneSignal in the sales application.
/// No other class should call the OneSignal SDK directly.
class OneSignalService {
  static const _appId = '37215f6d-f607-4864-b3de-6c78b4d4e64d';

  final navigatorKey = GlobalKey<NavigatorState>();
  bool _initialized = false;
  bool _openAssignedLeadsPending = false;
  bool Function()? _openAssignedLeads;

  Future<void> initialize() async {
    if (_initialized) return;

    await OneSignal.Debug.setLogLevel(OSLogLevel.none);
    await OneSignal.initialize(_appId);
    _initialized = true;

    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data?['screen'] == 'assigned_leads') {
        _openAssignedLeadsPending = true;
        _deliverPendingNavigation();
      }
    });
  }

  Future<void> login(String externalId) async {
    _requireInitialized();
    await OneSignal.login(externalId);
  }

  Future<void> logout() async {
    _requireInitialized();
    await OneSignal.logout();
  }

  Future<void> addEmail(String email) async {
    _requireInitialized();
    await OneSignal.User.addEmail(email);
  }

  Future<void> addSms(String number) async {
    _requireInitialized();
    await OneSignal.User.addSms(number);
  }

  Future<void> addTag(String key, String value) async {
    _requireInitialized();
    await OneSignal.User.addTagWithKey(key, value);
  }

  Future<void> setLogLevel(OSLogLevel level) async {
    await OneSignal.Debug.setLogLevel(level);
  }

  void setAssignedLeadsNavigationHandler(bool Function() handler) {
    _openAssignedLeads = handler;
    _deliverPendingNavigation();
  }

  void clearAssignedLeadsNavigationHandler(bool Function() handler) {
    if (_openAssignedLeads == handler) _openAssignedLeads = null;
  }

  void _deliverPendingNavigation() {
    final handler = _openAssignedLeads;
    if (!_openAssignedLeadsPending || handler == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (handler()) _openAssignedLeadsPending = false;
    });
  }

  bool consumeAssignedLeadsNavigation() {
    final pending = _openAssignedLeadsPending;
    _openAssignedLeadsPending = false;
    return pending;
  }

  void _requireInitialized() {
    if (!_initialized) {
      throw StateError('OneSignal must be initialized before use.');
    }
  }
}

final oneSignalService = OneSignalService();
