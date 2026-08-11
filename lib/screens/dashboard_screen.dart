import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/models/commission_summary.dart';
import 'package:real_estate_crm_sales/models/customer.dart';
import 'package:real_estate_crm_sales/models/lead.dart';
import 'package:real_estate_crm_sales/models/financial_summary.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/services/app_events.dart';
import 'package:real_estate_crm_sales/shared/crm_format.dart';
import 'package:real_estate_crm_sales/shared/contact_actions.dart';
import 'package:real_estate_crm_sales/screens/login_screen.dart';
import 'package:real_estate_crm_sales/services/one_signal_service.dart';
import 'package:real_estate_crm_sales/services/location_tracking_service.dart';
import 'package:real_estate_crm_sales/widgets/sales_card.dart';
import 'package:real_estate_crm_sales/widgets/screen_frame.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> data = _load();

  Future<_DashboardData> _load() async {
    final results = await Future.wait([
      apiClient.getProfile(),
      apiClient.getLeads(),
      apiClient.getBookedCustomers(),
      apiClient.getCommission(),
    ]);

    final customers = results[2] as List<Customer>;
    final financials = await Future.wait(customers.map((x) => apiClient.getCustomerFinancialSummary(x.id)));
    return _DashboardData(
      profile: results[0] as Map<String, dynamic>,
      leads: results[1] as List<Lead>,
      customers: results[2] as List<Customer>,
      financials: financials,
      commission: results[3] as CommissionSummary,
    );
  }

  @override
  void initState() {
    super.initState();
    AppEvents.instance.addListener(_onAppReload);
  }

  @override
  void dispose() {
    AppEvents.instance.removeListener(_onAppReload);
    super.dispose();
  }

  void _onAppReload() {
    if (mounted) {
      debugPrint('[DashboardScreen] Live auto-reloading dashboard data...');
      setState(() => data = _load());
    }
  }

  Future<void> _logout(BuildContext context) async {
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

    locationTrackingService.stop();
    await oneSignalService.logout();
    await apiClient.clearSession();
    if (!context.mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Today\'s Work',
      subtitle: 'SALES PIPELINE',
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            onPressed: () => setState(() => data = _load()),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh Dashboard',
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded, color: Color(0xffe11d48), size: 20),
            tooltip: 'Log Out',
          ),
        ],
      ),
      child: FutureBuilder<_DashboardData>(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              heightFactor: 6,
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              heightFactor: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() => data = _load()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final item = snapshot.data!;
          final totalOutstanding = item.financials.fold<num>(
            0,
            (total, summary) => total + summary.outstandingBalance,
          );

          final String userName = item.profile['fullName']?.toString() ?? 'Sales Executive';
          final String userEmail = item.profile['email']?.toString() ?? 'sales@crm.local';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium profile card
              SalesCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xff0f766e), Color(0xff0d9488)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Color(0xff0f172a),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            style: const TextStyle(
                              color: Color(0xff64748b),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xfff1f5f9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xffe2e8f0)),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Color(0xff0f766e),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Compact visual grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: [
                  _MetricTile(
                    label: 'Assigned Leads',
                    value: item.leads.length.toString(),
                    icon: Icons.person_search_rounded,
                    tileColor: const Color(0xff2563eb),
                  ),
                  _MetricTile(
                    label: 'Booked Clients',
                    value: item.customers.length.toString(),
                    icon: Icons.people_alt_rounded,
                    tileColor: const Color(0xff0f766e),
                  ),
                  _MetricTile(
                    label: 'Outstanding',
                    value: money(totalOutstanding),
                    icon: Icons.account_balance_wallet_outlined,
                    tileColor: const Color(0xffd97706),
                  ),
                  _MetricTile(
                    label: 'Commissions',
                    value: money(item.commission.totalEarned),
                    icon: Icons.workspace_premium_rounded,
                    tileColor: const Color(0xff7c3aed),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Lead queue card with fast quick actions
              SalesCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Leads',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: Color(0xff0f172a),
                          ),
                        ),
                        if (item.leads.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xffeff6ff),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${item.leads.length} total',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff2563eb),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (item.leads.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No assigned leads yet. Admin will distribute leads soon.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xff64748b),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: item.leads.take(4).length,
                        separatorBuilder: (_, __) => const Divider(color: Color(0xfff1f5f9), height: 16),
                        itemBuilder: (context, index) {
                          final lead = item.leads[index];
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lead.customerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: Color(0xff0f172a),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      lead.phone,
                                      style: const TextStyle(
                                        color: Color(0xff64748b),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton.filledTonal(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    onPressed: () => callPhone(context, lead.phone),
                                    icon: const Icon(Icons.call, size: 16),
                                    tooltip: 'Call client',
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton.filledTonal(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    onPressed: () => openWhatsApp(context, lead.phone),
                                    icon: const WhatsAppIcon(size: 16),
                                    tooltip: 'WhatsApp client',
                                  ),
                                  const SizedBox(width: 8),
                                  StatusPill(label: enumLabel(leadStatuses, lead.status)),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tileColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tileColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfff1f5f9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0f172a).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: tileColor, size: 20),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tileColor.withOpacity(0.4),
                ),
              )
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff64748b),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.profile,
    required this.leads,
    required this.customers,
    required this.financials,
    required this.commission,
  });

  final Map<String, dynamic> profile;
  final List<Lead> leads;
  final List<Customer> customers;
  final List<FinancialSummary> financials;
  final CommissionSummary commission;
}
