import 'package:flutter/foundation.dart';

class AppEvents extends ChangeNotifier {
  static final AppEvents instance = AppEvents._internal();
  AppEvents._internal();

  void notifyReload() {
    debugPrint('[AppEvents] Broadcasting reload signal.');
    notifyListeners();
  }
}
