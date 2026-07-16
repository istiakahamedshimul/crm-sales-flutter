import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/models/customer.dart';
import 'package:real_estate_crm_sales/models/invoice.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/shared/crm_format.dart';
import 'package:real_estate_crm_sales/widgets/empty_state.dart';
import 'package:real_estate_crm_sales/widgets/sales_card.dart';
import 'package:real_estate_crm_sales/widgets/screen_frame.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  late Future<List<Invoice>> invoices;

  @override
  void initState() {
    super.initState();
    invoices = apiClient.getInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Invoices',
      subtitle: 'CUSTOMER BILLING',
      action: IconButton.filled(
        onPressed: openCreateInvoice,
        icon: const Icon(Icons.add),
      ),
      child: FutureBuilder<List<Invoice>>(
        future: invoices,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                heightFactor: 8, child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const EmptyState(text: 'No invoices generated yet.');
          }

          return Column(
            children: [
              for (final invoice in data) ...[
                SalesCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(invoice.invoiceNumber,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17))),
                          StatusPill(
                              label:
                                  enumLabel(invoiceStatuses, invoice.status)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(invoice.customer,
                          style: const TextStyle(
                              color: Color(0xff667085),
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(money(invoice.finalAmount),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 20)),
                          Text('Due ${shortDate(invoice.dueDate)}',
                              style: const TextStyle(color: Color(0xff667085))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> openCreateInvoice() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CreateInvoiceSheet(),
    );
    if (created == true) setState(() => invoices = apiClient.getInvoices());
  }
}

class _CreateInvoiceSheet extends StatefulWidget {
  const _CreateInvoiceSheet();

  @override
  State<_CreateInvoiceSheet> createState() => _CreateInvoiceSheetState();
}

class _CreateInvoiceSheetState extends State<_CreateInvoiceSheet> {
  final amount = TextEditingController();
  final discount = TextEditingController(text: '0');
  final tax = TextEditingController(text: '0');
  late Future<List<Customer>> customers;
  int? customerId;
  bool loading = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    customers = apiClient.getCustomers().then((list) {
      debugPrint('[InvoiceSheet] customers loaded: ${list.length}');
      return list;
    }).catchError((e) {
      debugPrint('[InvoiceSheet] customers error: $e');
      throw e;
    });
  }

  @override
  void dispose() {
    amount.dispose();
    discount.dispose();
    tax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18),
      child: FutureBuilder<List<Customer>>(
        future: customers,
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          final loadingCustomers = snapshot.connectionState == ConnectionState.waiting;
          final customerError = snapshot.hasError ? snapshot.error.toString().replaceFirst('Exception: ', '') : '';
          return ListView(
            shrinkWrap: true,
            children: [
              Text('Generate Invoice',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              if (loadingCustomers)
                const Center(child: CircularProgressIndicator())
              else if (customerError.isNotEmpty)
                Text(customerError, style: const TextStyle(color: Colors.red))
              else
              DropdownButtonFormField<int>(
                value: customerId,
                decoration: const InputDecoration(labelText: 'Customer'),
                items: [
                  for (final customer in data)
                    DropdownMenuItem(
                        value: customer.id, child: Text(customer.name))
                ],
                onChanged: (value) => setState(() => customerId = value),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount')),
              const SizedBox(height: 12),
              TextField(
                  controller: discount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Discount')),
              const SizedBox(height: 12),
              TextField(
                  controller: tax,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tax / VAT')),
              if (error.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(error,
                        style: const TextStyle(color: Color(0xffb42318)))),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: loading ? null : submit,
                  child: Text(loading ? 'Creating...' : 'Create Invoice')),
            ],
          );
        },
      ),
    );
  }

  Future<void> submit() async {
    if (customerId == null) {
      setState(() => error = 'Select a customer first.');
      return;
    }
    setState(() {
      loading = true;
      error = '';
    });
    try {
      await apiClient.createInvoice(
        customerId: customerId!,
        amount: double.parse(amount.text),
        discount: double.tryParse(discount.text) ?? 0,
        tax: double.tryParse(tax.text) ?? 0,
        dueDate: DateTime.now().add(const Duration(days: 7)),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      setState(() => error = exception.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
