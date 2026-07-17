import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/app/sales_crm_app.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/services/one_signal_service.dart';

export 'package:real_estate_crm_sales/app/sales_crm_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await oneSignalService.initialize();
  await apiClient.loadSession();
  if (apiClient.userId != null) {
    await oneSignalService.login('crm-user-${apiClient.userId}');
  }
  runApp(SalesCrmApp(isLoggedIn: apiClient.token.isNotEmpty));
}
