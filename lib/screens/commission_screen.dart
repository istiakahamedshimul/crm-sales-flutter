import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/models/commission_summary.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/shared/crm_format.dart';
import 'package:real_estate_crm_sales/widgets/sales_card.dart';
import 'package:real_estate_crm_sales/widgets/screen_frame.dart';

class CommissionScreen extends StatefulWidget {
  const CommissionScreen({super.key});

  @override
  State<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends State<CommissionScreen> {
  late Future<CommissionSummary> commission = apiClient.getCommission();

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Commission Wallet',
      subtitle: 'EARNINGS',
      action: IconButton.filledTonal(
        onPressed: () => setState(() => commission = apiClient.getCommission()),
        icon: const Icon(Icons.refresh),
      ),
      child: FutureBuilder<CommissionSummary>(
        future: commission,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                heightFactor: 8, child: CircularProgressIndicator());
          }

          final data = snapshot.data ??
              const CommissionSummary(
                  totalEarned: 0, pending: 0, paid: 0, history: []);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xff111827),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total earned',
                        style: TextStyle(
                            color: Color(0xffcbd5e1),
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Text(money(data.totalEarned),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                            child: _WalletMini(
                                label: 'Pending', value: money(data.pending))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _WalletMini(
                                label: 'Paid', value: money(data.paid))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('History',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 10),
              if (data.history.isEmpty)
                const SalesCard(child: Text('No commission history yet.')),
              for (final row in data.history) ...[
                SalesCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(money(row.amount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 18)),
                            Text(
                                '${row.percentage}% from ${money(row.paymentAmount)}',
                                style:
                                    const TextStyle(color: Color(0xff667085))),
                          ],
                        ),
                      ),
                      StatusPill(
                          label: enumLabel(commissionStatuses, row.status)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _WalletMini extends StatelessWidget {
  const _WalletMini({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xffcbd5e1), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
