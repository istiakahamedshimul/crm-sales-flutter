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
          primary: const Color(0xff0f766e),
          secondary: const Color(0xff0d9488),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff8fafc),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xff0f172a),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
          iconTheme: IconThemeData(color: Color(0xff0f172a)),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xffe2e8f0), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffe2e8f0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffe2e8f0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xff0f766e), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          labelStyle: const TextStyle(color: Color(0xff64748b), fontSize: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: Color(0xffcbd5e1)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      home: widget.isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
