import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/app/sales_crm_app.dart';
import 'package:real_estate_crm_sales/screens/home_screen.dart';
import 'package:real_estate_crm_sales/screens/login_screen.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';

export 'package:real_estate_crm_sales/app/sales_crm_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await apiClient.loadSession();
  runApp(SalesCrmApp(isLoggedIn: apiClient.token.isNotEmpty));
}
