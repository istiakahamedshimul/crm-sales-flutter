import 'dart:async';
import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/screens/commission_screen.dart';
import 'package:real_estate_crm_sales/screens/customers_screen.dart';
import 'package:real_estate_crm_sales/screens/dashboard_screen.dart';
import 'package:real_estate_crm_sales/screens/followups_screen.dart';
import 'package:real_estate_crm_sales/screens/leads_screen.dart';
import 'package:real_estate_crm_sales/screens/login_screen.dart';
import 'package:real_estate_crm_sales/screens/payments_screen.dart';
import 'package:real_estate_crm_sales/screens/vehicle_bookings_screen.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/services/one_signal_service.dart';
import 'package:real_estate_crm_sales/services/app_events.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int index;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    oneSignalService.setAssignedLeadsNavigationHandler(_openAssignedLeads);
    
    // Auto-sync in the background every 20 seconds to keep all screens updated live
    _syncTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (mounted) {
        debugPrint('[HomeScreen] Triggering periodic background sync...');
        AppEvents.instance.notifyReload();
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
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
    final pages = [
      const DashboardScreen(),
      const LeadsScreen(),
      const FollowUpsScreen(),
      const CustomersScreen(),
      const PaymentsScreen(),
      const CommissionScreen(),
      const VehicleBookingsScreen(),
      const SizedBox(), // logout placeholder
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        height: 68,
        elevation: 10,
        backgroundColor: Colors.white,
        shadowColor: const Color(0xff0f172a).withOpacity(0.4),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (value) {
          if (value == 7) {
            _logout();
            return;
          }
          setState(() => index = value);
          // Instantly refresh the newly selected screen
          AppEvents.instance.notifyReload();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, size: 22),
            selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xff0f766e), size: 22),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_search_outlined, size: 22),
            selectedIcon: Icon(Icons.person_search_rounded, color: Color(0xff0f766e), size: 22),
            label: 'Leads',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined, size: 22),
            selectedIcon: Icon(Icons.history_rounded, color: Color(0xff0f766e), size: 22),
            label: 'Updates',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined, size: 22),
            selectedIcon: Icon(Icons.contacts_rounded, color: Color(0xff0f766e), size: 22),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined, size: 22),
            selectedIcon: Icon(Icons.payments_rounded, color: Color(0xff0f766e), size: 22),
            label: 'Pay',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined, size: 22),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: Color(0xff0f766e), size: 22),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined, size: 22),
            selectedIcon: Icon(Icons.directions_car_rounded, color: Color(0xff0f766e), size: 22),
            label: 'Visits',
          ),
          NavigationDestination(
            icon: Icon(Icons.logout_outlined, size: 22),
            selectedIcon: Icon(Icons.logout_rounded, color: Colors.red, size: 22),
            label: 'Logout',
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out from your sales workspace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xffe11d48)),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await oneSignalService.logout();
    await apiClient.clearSession();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}
