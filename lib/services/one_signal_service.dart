import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// The single integration point for OneSignal in the sales application.
/// No other class should call the OneSignal SDK directly.
class OneSignalService {
  static const _appId = '37215f6d-f607-4864-b3de-6c78b4d4e64d';

  final navigatorKey = GlobalKey<NavigatorState>();
  bool _initialized = false;
  bool _dialogShown = false;
  bool _registrationPending = false;
  bool _openAssignedLeadsPending = false;
  bool Function()? _openAssignedLeads;

  Future<void> initialize() async {
    if (_initialized) return;

    await OneSignal.Debug.setLogLevel(OSLogLevel.none);
    await OneSignal.initialize(_appId);
    _initialized = true;

    OneSignal.User.pushSubscription.addObserver((state) {
      _handleSubscriptionId(state.current.id);
    });
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data?['screen'] == 'assigned_leads') {
        _openAssignedLeadsPending = true;
        _deliverPendingNavigation();
      }
    });
    _handleSubscriptionId(OneSignal.User.pushSubscription.id);

    // The navigator is attached by MaterialApp after initialization.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDialogIfReady());
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

  void _handleSubscriptionId(String? id) {
    if (id == null || id.isEmpty || id.startsWith('local-')) return;
    _registrationPending = true;
    _showDialogIfReady();
  }

  void _showDialogIfReady() {
    final context = navigatorKey.currentContext;
    if (!_registrationPending || _dialogShown || context == null) return;

    _dialogShown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Your OneSignal SDK integration is complete!'),
        content: const Text(
          'You can now send Push Notifications & In-App Messages through '
          'OneSignal. Tap below to enable push notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await OneSignal.Notifications.requestPermission(true);
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _requireInitialized() {
    if (!_initialized) {
      throw StateError('OneSignal must be initialized before use.');
    }
  }
}

final oneSignalService = OneSignalService();
