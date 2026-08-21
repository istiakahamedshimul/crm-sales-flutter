import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:real_estate_crm_sales/models/payment.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/services/app_events.dart';
import 'package:real_estate_crm_sales/shared/crm_format.dart';
import 'package:real_estate_crm_sales/widgets/sales_card.dart';
import 'package:real_estate_crm_sales/widgets/screen_frame.dart';

class CustomerPaymentsScreen extends StatefulWidget {
  const CustomerPaymentsScreen({super.key});

  @override
  State<CustomerPaymentsScreen> createState() => _CustomerPaymentsScreenState();
}

class _CustomerPaymentsScreenState extends State<CustomerPaymentsScreen> {
  late Future<List<Payment>> payments = apiClient.getMyCustomerPayments();

  @override
  void initState() {
    super.initState();
    AppEvents.instance.addListener(_reload);
  }

  @override
  void dispose() {
    AppEvents.instance.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) setState(() => payments = apiClient.getMyCustomerPayments());
  }

  String _status(Payment payment) {
    if (payment.isReversed) return 'Reversed';
    const values = ['Pending', 'Approved', 'Rejected'];
    final value = payment.status;
    return value is int && value >= 0 && value < values.length ? values[value] : value.toString();
  }

  @override
  Widget build(BuildContext context) => ScreenFrame(
        title: 'Customer Payments',
        subtitle: 'CLIENT COLLECTIONS',
        action: IconButton.filledTonal(onPressed: _reload, icon: const Icon(Icons.refresh_rounded)),
        child: FutureBuilder<List<Payment>>(
          future: payments,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(heightFactor: 6, child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)));
            }
            final rows = snapshot.data ?? const <Payment>[];
            if (rows.isEmpty) {
              return const SalesCard(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No payments have been recorded for your booked customers.'))));
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final row = rows[index];
                return SalesCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(row.customer, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                      Text(money(row.amount), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xff0f766e))),
                    ]),
                    const SizedBox(height: 8),
                    Text(row.collectionNumber, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xff475569))),
                    const SizedBox(height: 4),
                    Text('${row.paymentDate == null ? '' : DateFormat('dd MMM yyyy').format(row.paymentDate!.toLocal())}  •  ${_status(row)}'),
                    Text('File ID: ${row.fileId?.trim().isNotEmpty == true ? row.fileId : 'Not assigned'}'),
                    if (row.remarks?.isNotEmpty == true) Text('Details: ${row.remarks}'),
                    if (row.reversalReason?.isNotEmpty == true) Text('Reversal: ${row.reversalReason}', style: const TextStyle(color: Colors.red)),
                  ]),
                );
              },
            );
          },
        ),
      );
}
