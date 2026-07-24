import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:real_estate_crm_sales/models/customer.dart';
import 'package:real_estate_crm_sales/models/payment.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/services/app_events.dart';
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
      debugPrint('[PaymentsScreen] Live auto-reloading collections data...');
      setState(() => payments = apiClient.getPayments());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Collections',
      subtitle: 'RECEIPT PROOF',
      action: IconButton.filled(
        onPressed: submitPayment,
        icon: const Icon(Icons.upload_file_outlined, size: 20),
        tooltip: 'Upload Receipt',
      ),
      child: FutureBuilder<List<Payment>>(
        future: payments,
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
                    onPressed: () => setState(() => payments = apiClient.getPayments()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const EmptyState(
              text: 'No payment collections submitted yet. Use the + upload button.',
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final payment = data[index];
              final isRejected = payment.status == 2;
              return SalesCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xffeff6ff),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xff2563eb),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                payment.customer,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xff0f172a),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Receipt: ${payment.collectionNumber}',
                                style: const TextStyle(
                                  color: Color(0xff64748b),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusPill(label: enumLabel(paymentStatuses, payment.status)),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xfff1f5f9)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'COLLECTED AMOUNT',
                              style: TextStyle(
                                color: Color(0xff94a3b8),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              money(payment.amount),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xff0f172a),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (isRejected && payment.rejectReason != null && payment.rejectReason!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xfffef2f2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xfffee2e2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: Color(0xffef4444),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'REJECTION REMARK',
                                    style: TextStyle(
                                      color: Color(0xffb91c1c),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    payment.rejectReason!,
                                    style: const TextStyle(
                                      color: Color(0xff991b1b),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PaymentSheet(),
    );
    if (submitted == true) {
      AppEvents.instance.notifyReload();
    }
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
  late Future<List<Customer>> customers = apiClient.getBookedCustomers();
  int? customerId;
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
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: FutureBuilder<List<Customer>>(
        future: customers,
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          return ListView(
            shrinkWrap: true,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Submit Collection',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xff0f172a),
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context, false),
                  )
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: customerId,
                decoration: const InputDecoration(labelText: 'Select Booked Customer'),
                items: [
                  for (final customer in data)
                    DropdownMenuItem(
                      value: customer.id,
                      child: Text('${customer.name} (${customer.phone})', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() => customerId = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Collected Amount (BDT)',
                  prefixIcon: Icon(Icons.currency_lira_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: proof,
                decoration: const InputDecoration(
                  labelText: 'Receipt Image Link / Proof URL',
                  prefixIcon: Icon(Icons.link_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: pickProof,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(
                  selectedFilePath == null
                      ? 'Upload Local receipt file'
                      : selectedFilePath!.split(RegExp(r'[\\/]')).last,
                ),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error,
                    style: const TextStyle(color: Color(0xffef4444), fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: loading ? null : submit,
                child: Text(loading ? 'Uploading receipt...' : 'Submit for Approval'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> submit() async {
    if (customerId == null) {
      setState(() => error = 'Please select a booked customer first.');
      return;
    }
    final parsedAmount = double.tryParse(amount.text);
    if (parsedAmount == null || parsedAmount <= 0) {
      setState(() => error = 'Collection amount must be a positive number.');
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

      if (proofUrl.isEmpty) {
        throw Exception('Please select a receipt file or provide proof link.');
      }
      
      await apiClient.submitCollection(customerId!, parsedAmount, proofUrl);
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      setState(() => error = exception.toString().replaceFirst('Exception: ', ''));
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
