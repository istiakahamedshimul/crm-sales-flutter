import 'dart:async';
import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/screens/customers_screen.dart';
import 'package:real_estate_crm_sales/screens/dashboard_screen.dart';
import 'package:real_estate_crm_sales/screens/leads_screen.dart';
import 'package:real_estate_crm_sales/screens/notifications_screen.dart';
import 'package:real_estate_crm_sales/screens/daily_work_report_screen.dart';
import 'package:real_estate_crm_sales/screens/profile_screen.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/services/one_signal_service.dart';
import 'package:real_estate_crm_sales/services/app_events.dart';
import 'package:real_estate_crm_sales/services/location_tracking_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int index;
  Timer? _syncTimer;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    _pageController = PageController(initialPage: index);
    oneSignalService.setAssignedLeadsNavigationHandler(_openAssignedLeads);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _startLocationTracking());

    // Auto-sync in the background every 20 seconds to keep all screens updated live
    _syncTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (mounted) {
        debugPrint('[HomeScreen] Triggering periodic background sync...');
        AppEvents.instance.notifyReload();
      }
    });
  }

  Future<void> _startLocationTracking() async {
    final enabled = await locationTrackingService.loadEnabled();
    if (!enabled) return;
    await locationTrackingService.startWithPermission();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _pageController.dispose();
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
      const CustomersScreen(),
      const NotificationsScreen(),
      const DailyWorkReportScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (value) {
          setState(() {
            index = value;
          });
        },
        physics:
            const ClampingScrollPhysics(), // Slide screen by screen smoothly
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        height: 68,
        elevation: 10,
        backgroundColor: Colors.white,
        shadowColor: const Color(0xff0f172a).withOpacity(0.4),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (value) {
          setState(() => index = value);
          _pageController.animateToPage(
            value,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          // Instantly refresh the newly selected screen
          AppEvents.instance.notifyReload();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded, size: 22),
            selectedIcon: Icon(Icons.grid_view_rounded,
                color: Color(0xff0f766e), size: 22),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_ind_outlined, size: 22),
            selectedIcon: Icon(Icons.assignment_ind_rounded,
                color: Color(0xff0f766e), size: 22),
            label: 'Pipeline',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded, size: 22),
            selectedIcon: Icon(Icons.people_alt_rounded,
                color: Color(0xff0f766e), size: 22),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined, size: 22),
            selectedIcon: Icon(Icons.notifications_rounded,
                color: Color(0xff0f766e), size: 22),
            label: 'Alerts',
          ),
          NavigationDestination(
              icon: Icon(Icons.edit_note_rounded, size: 22),
              selectedIcon: Icon(Icons.edit_note_rounded,
                  color: Color(0xff0f766e), size: 22),
              label: 'Report'),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, size: 22),
            selectedIcon:
                Icon(Icons.person_rounded, color: Color(0xff0f766e), size: 22),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
