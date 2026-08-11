import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:real_estate_crm_sales/models/customer.dart';
import 'package:real_estate_crm_sales/models/financial_summary.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/services/app_events.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('My Clients'), actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(
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
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final customer = rows[index];
                return Card(child: ListTile(
                  leading: CircleAvatar(child: Text(customer.name.isEmpty ? 'C' : customer.name[0])),
                  title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${customer.project ?? 'No project'}\n${customer.phone}'), isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerFinancialScreen(customer: customer))),
                ));
              },
            );
          },
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
