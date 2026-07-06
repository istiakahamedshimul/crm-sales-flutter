import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/screens/commission_screen.dart';
import 'package:real_estate_crm_sales/screens/customers_screen.dart';
import 'package:real_estate_crm_sales/screens/dashboard_screen.dart';
import 'package:real_estate_crm_sales/screens/followups_screen.dart';
import 'package:real_estate_crm_sales/screens/invoices_screen.dart';
import 'package:real_estate_crm_sales/screens/leads_screen.dart';
import 'package:real_estate_crm_sales/screens/payments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardScreen(),
      const LeadsScreen(),
      const FollowUpsScreen(),
      const CustomersScreen(),
      const InvoicesScreen(),
      const PaymentsScreen(),
      const CommissionScreen(),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_work_outlined),
              selectedIcon: Icon(Icons.home_work_rounded),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.person_search_outlined),
              selectedIcon: Icon(Icons.person_search_rounded),
              label: 'Leads'),
          NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check_rounded),
              label: 'Updates'),
          NavigationDestination(
              icon: Icon(Icons.contacts_outlined),
              selectedIcon: Icon(Icons.contacts_rounded),
              label: 'Customers'),
          NavigationDestination(
              icon: Icon(Icons.request_quote_outlined),
              selectedIcon: Icon(Icons.request_quote_rounded),
              label: 'Invoices'),
          NavigationDestination(
              icon: Icon(Icons.price_check_outlined),
              selectedIcon: Icon(Icons.price_check_rounded),
              label: 'Payments'),
          NavigationDestination(
              icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings_rounded),
              label: 'Wallet'),
        ],
      ),
    );
  }
}
