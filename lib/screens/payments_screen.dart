import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:real_estate_crm_sales/models/invoice.dart';
import 'package:real_estate_crm_sales/models/payment.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/shared/crm_format.dart';
import 'package:real_estate_crm_sales/widgets/empty_state.dart';
import 'package:real_estate_crm_sales/widgets/sales_card.dart';
import 'package:real_estate_crm_sales/widgets/screen_frame.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late Future<List<Payment>> payments = apiClient.getPayments();

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Collections',
      subtitle: 'PAYMENT PROOF',
      action: IconButton.filled(
        onPressed: submitPayment,
        icon: const Icon(Icons.upload_file_outlined),
      ),
      child: FutureBuilder<List<Payment>>(
        future: payments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                heightFactor: 8, child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const EmptyState(text: 'No payment submissions yet.');
          }

          return Column(
            children: [
              for (final payment in data) ...[
                SalesCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(payment.customer,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900))),
                          StatusPill(
                              label:
                                  enumLabel(paymentStatuses, payment.status)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(payment.invoiceNumber,
                          style: const TextStyle(
                              color: Color(0xff667085),
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Text(money(payment.amount),
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900)),
                      if (payment.rejectReason != null &&
                          payment.rejectReason!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(payment.rejectReason!,
                            style: const TextStyle(
                                color: Color(0xffb42318),
                                fontWeight: FontWeight.w700)),
                      ],
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

  Future<void> submitPayment() async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _PaymentSheet(),
    );
    if (submitted == true) setState(() => payments = apiClient.getPayments());
  }
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet();

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final amount = TextEditingController();
  final proof = TextEditingController();
  String? selectedFilePath;
  late Future<List<Invoice>> invoices = apiClient.getInvoices();
  int? invoiceId;
  bool loading = false;
  String error = '';

  @override
  void dispose() {
    amount.dispose();
    proof.dispose();
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
      child: FutureBuilder<List<Invoice>>(
        future: invoices,
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          return ListView(
            shrinkWrap: true,
            children: [
              Text('Submit Payment Proof',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: invoiceId,
                decoration: const InputDecoration(labelText: 'Invoice'),
                items: [
                  for (final invoice in data)
                    DropdownMenuItem(
                        value: invoice.id,
                        child: Text(
                            '${invoice.invoiceNumber} - ${money(invoice.finalAmount)}')),
                ],
                onChanged: (value) => setState(() => invoiceId = value),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Collected amount')),
              const SizedBox(height: 12),
              TextField(
                  controller: proof,
                  decoration: const InputDecoration(
                      labelText: 'Proof URL / uploaded receipt URL')),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: pickProof,
                icon: const Icon(Icons.attach_file),
                label: Text(selectedFilePath == null
                    ? 'Choose receipt/proof file'
                    : selectedFilePath!.split(RegExp(r'[\\/]')).last),
              ),
              if (error.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(error,
                        style: const TextStyle(color: Color(0xffb42318)))),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: loading ? null : submit,
                  child:
                      Text(loading ? 'Submitting...' : 'Submit for Approval')),
            ],
          );
        },
      ),
    );
  }

  Future<void> submit() async {
    if (invoiceId == null) {
      setState(() => error = 'Select an invoice first.');
      return;
    }
    setState(() {
      loading = true;
      error = '';
    });
    try {
      var proofUrl = proof.text.trim();
      if (selectedFilePath != null) {
        proofUrl = await apiClient.uploadFile(
          selectedFilePath!,
          category: 'payments',
        );
      }

      await apiClient.submitPayment(
          invoiceId!, double.parse(amount.text), proofUrl);
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickProof() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    final path = result?.files.single.path;
    if (path != null) {
      setState(() => selectedFilePath = path);
    }
  }
}
