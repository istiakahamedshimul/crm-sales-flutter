import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/models/commission_summary.dart';
import 'package:real_estate_crm_sales/models/invoice.dart';
import 'package:real_estate_crm_sales/models/lead.dart';
import 'package:real_estate_crm_sales/models/payment.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/shared/crm_format.dart';
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
      apiClient.getInvoices(),
      apiClient.getPayments(),
      apiClient.getCommission(),
    ]);

    return _DashboardData(
      profile: results[0] as Map<String, dynamic>,
      leads: results[1] as List<Lead>,
      invoices: results[2] as List<Invoice>,
      payments: results[3] as List<Payment>,
      commission: results[4] as CommissionSummary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Today\'s Work',
      subtitle: 'SALES DASHBOARD',
      action: IconButton.filledTonal(
        onPressed: () => setState(() => data = _load()),
        icon: const Icon(Icons.refresh),
      ),
      child: FutureBuilder<_DashboardData>(
        future: data,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                heightFactor: 8, child: CircularProgressIndicator());
          }
          final item = snapshot.data!;
          final pendingPayments =
              item.payments.where((payment) => payment.status == 0).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SalesCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xff0f766e),
                      child: Text(
                        (item.profile['fullName']?.toString().isNotEmpty ??
                                false)
                            ? item.profile['fullName'].toString()[0]
                            : 'S',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              item.profile['fullName']?.toString() ??
                                  'Sales Executive',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(item.profile['email']?.toString() ?? '',
                              style: const TextStyle(color: Color(0xff667085))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.28,
                children: [
                  _MetricTile(
                      label: 'Assigned Leads',
                      value: item.leads.length.toString(),
                      icon: Icons.assignment_ind_outlined),
                  _MetricTile(
                      label: 'Invoices',
                      value: item.invoices.length.toString(),
                      icon: Icons.receipt_long_outlined),
                  _MetricTile(
                      label: 'Pending Payments',
                      value: pendingPayments.toString(),
                      icon: Icons.pending_actions_outlined),
                  _MetricTile(
                      label: 'Commission',
                      value: money(item.commission.pending),
                      icon: Icons.account_balance_wallet_outlined),
                ],
              ),
              const SizedBox(height: 14),
              SalesCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hot follow-up queue',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 17)),
                    const SizedBox(height: 10),
                    for (final lead in item.leads.take(4))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(lead.customerName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(lead.phone),
                        trailing: StatusPill(
                            label: enumLabel(leadStatuses, lead.status)),
                      ),
                    if (item.leads.isEmpty)
                      const Text('No assigned leads yet.',
                          style: TextStyle(color: Color(0xff667085))),
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
  const _MetricTile(
      {required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SalesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(
                  color: Color(0xff667085), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.profile,
    required this.leads,
    required this.invoices,
    required this.payments,
    required this.commission,
  });

  final Map<String, dynamic> profile;
  final List<Lead> leads;
  final List<Invoice> invoices;
  final List<Payment> payments;
  final CommissionSummary commission;
}
