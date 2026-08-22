import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:real_estate_crm_sales/models/customer.dart';
import 'package:real_estate_crm_sales/models/financial_summary.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/services/app_events.dart';
import 'package:real_estate_crm_sales/screens/customer_payments_screen.dart';
import 'package:real_estate_crm_sales/shared/crm_format.dart';
import 'package:real_estate_crm_sales/shared/contact_actions.dart';
import 'package:real_estate_crm_sales/widgets/sales_card.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late Future<List<Customer>> data;
  @override void initState() { super.initState(); _load(); AppEvents.instance.addListener(_refresh); }
  @override void dispose() { AppEvents.instance.removeListener(_refresh); super.dispose(); }
  void _load() => data = apiClient.getBookedCustomers();
  void _refresh() { if (mounted) setState(_load); }

  @override Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text('My Clients'),
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))],
        bottom: const TabBar(tabs: [Tab(text: 'Clients', icon: Icon(Icons.people_alt_rounded)), Tab(text: 'Payments', icon: Icon(Icons.receipt_long_rounded))]),
      ),
      body: TabBarView(children: [RefreshIndicator(
        onRefresh: () async { _refresh(); await data; },
        child: FutureBuilder<List<Customer>>(
          future: data,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return ListView(children: [SizedBox(height: MediaQuery.sizeOf(context).height * .6, child: Center(child: snapshot.hasError ? Text('${snapshot.error}') : const CircularProgressIndicator()))]);
            }
            final rows = snapshot.data!;
            if (rows.isEmpty) return ListView(children: const [Padding(padding: EdgeInsets.all(48), child: Center(child: Text('No assigned booked customers.')))]);
            return ListView.separated(
              padding: const EdgeInsets.all(12), itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final customer = rows[index];
                return SalesCard(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerFinancialScreen(customer: customer))),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xff0f172a),
                                  ),
                                ),
                                if (customer.project != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.apartment_rounded, size: 14, color: Color(0xff64748b)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          customer.project!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xff475569),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusPill(
                            label: customer.projectType == null ? 'General' : enumLabel(projectTypes, customer.projectType),
                          ),
                        ],
                      ),
                      Builder(
                        builder: (context) {
                          final showPaymentStatus = customer.paymentStatus.toLowerCase().trim() != 'unpaid';
                          final showSalesExecutive = customer.salesExecutive != null && customer.salesExecutive!.trim().isNotEmpty;
                          if (showPaymentStatus || showSalesExecutive) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                children: [
                                  if (showPaymentStatus)
                                    StatusPill(label: customer.paymentStatus),
                                  if (showPaymentStatus && showSalesExecutive)
                                    const SizedBox(width: 8),
                                  if (showSalesExecutive)
                                    StatusPill(label: 'Exec: ${customer.salesExecutive}'),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const Divider(height: 24, color: Color(0xfff1f5f9)),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.phone_iphone_rounded, size: 14, color: Color(0xff64748b)),
                                const SizedBox(width: 6),
                                Text(
                                  customer.phone,
                                  style: const TextStyle(
                                    color: Color(0xff64748b),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ActionButton(
                                icon: const Icon(Icons.call, size: 18, color: Color(0xff475569)),
                                onPressed: () => callPhone(context, customer.phone),
                                tooltip: 'Call client',
                              ),
                              const SizedBox(width: 6),
                              _ActionButton(
                                icon: const WhatsAppIcon(size: 18),
                                onPressed: () => openWhatsApp(context, customer.phone),
                                tooltip: 'WhatsApp client',
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right, color: Color(0xff94a3b8)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ), const CustomerPaymentsScreen()]),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final Widget icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xfff1f5f9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xffe2e8f0),
              width: 1.0,
            ),
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }
}


class CustomerFinancialScreen extends StatelessWidget {
  const CustomerFinancialScreen({super.key, required this.customer});
  final Customer customer;
  String money(double value) => NumberFormat.currency(symbol: 'BDT ', decimalDigits: 2).format(value);

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      body: FutureBuilder<FinancialSummary>(
        future: apiClient.getCustomerFinancialSummary(customer.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: snapshot.hasError ? Text('${snapshot.error}') : const CircularProgressIndicator());
          final summary = snapshot.data!;
          final values = [('Total agreed', summary.totalAgreedAmount), ('Total paid', summary.totalPaid), ('Current due', summary.currentDue), ('Overdue', summary.overdueAmount), ('Outstanding', summary.outstandingBalance)];
          return ListView(padding: const EdgeInsets.all(16), children: [
            Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(summary.paymentStatus, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              ...values.map((value) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(value.$1), Text(money(value.$2), style: const TextStyle(fontWeight: FontWeight.w800))]))),
              const Divider(),
              ListTile(contentPadding: EdgeInsets.zero, title: const Text('Next EMI'), subtitle: Text(summary.nextEmiDueDate == null ? 'No upcoming installment' : DateFormat('dd MMM yyyy').format(summary.nextEmiDueDate!.toLocal())), trailing: Text(summary.nextEmiAmount == null ? '—' : money(summary.nextEmiAmount!), style: const TextStyle(fontWeight: FontWeight.w900))),
            ]))),
          ]);
        },
      ),
    );
  }
}
