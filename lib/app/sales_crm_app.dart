import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/screens/home_screen.dart';
import 'package:real_estate_crm_sales/screens/login_screen.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/services/one_signal_service.dart';

class SalesCrmApp extends StatefulWidget {
  const SalesCrmApp({super.key, required this.isLoggedIn});

  final bool isLoggedIn;

  @override
  State<SalesCrmApp> createState() => _SalesCrmAppState();
}

class _SalesCrmAppState extends State<SalesCrmApp> {
  @override
  void initState() {
    super.initState();
    oneSignalService.setAssignedLeadsNavigationHandler(_openAssignedLeads);
  }

  @override
  void dispose() {
    oneSignalService.clearAssignedLeadsNavigationHandler(_openAssignedLeads);
    super.dispose();
  }

  bool _openAssignedLeads() {
    if (apiClient.token.isEmpty) return false;
    oneSignalService.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 1)),
      (_) => false,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: oneSignalService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'CRM Sales',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0f766e),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff5f7f8),
        cardTheme: CardTheme(
          elevation: 0,
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xffd7dee4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xffd7dee4)),
          ),
        ),
      ),
      home: widget.isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
