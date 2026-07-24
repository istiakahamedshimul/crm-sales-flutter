import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/models/commission_summary.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/services/app_events.dart';
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
      debugPrint('[CommissionScreen] Live auto-reloading commission summary...');
      setState(() => commission = apiClient.getCommission());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'My Commission',
      subtitle: 'WALLET & EARNINGS',
      action: IconButton.filledTonal(
        onPressed: () => setState(() => commission = apiClient.getCommission()),
        icon: const Icon(Icons.refresh_rounded, size: 20),
      ),
      child: FutureBuilder<CommissionSummary>(
        future: commission,
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
                    onPressed: () => setState(() => commission = apiClient.getCommission()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ??
              const CommissionSummary(
                  totalEarned: 0, pending: 0, paid: 0, history: []);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Wallet balance container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xff0f172a), Color(0xff1e293b)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff0f172a).withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL EARNED',
                          style: TextStyle(
                            color: Color(0xff94a3b8),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      money(data.totalEarned),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _WalletMini(
                            label: 'Pending Balance',
                            value: money(data.pending),
                            textColor: const Color(0xfffbbf24), // Amber
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _WalletMini(
                            label: 'Paid to Wallet',
                            value: money(data.paid),
                            textColor: const Color(0xff2dd4bf), // Teal/Green
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Earning History',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xff0f172a),
                ),
              ),
              const SizedBox(height: 12),
              if (data.history.isEmpty)
                const SalesCard(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No commission logs generated yet.',
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
                  itemCount: data.history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final row = data.history[index];
                    return SalesCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xfff1f5f9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.insights_rounded,
                              color: Color(0xff0f766e),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  money(row.amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                    color: Color(0xff0f172a),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${row.percentage}% from payout of ${money(row.paymentAmount)}',
                                  style: const TextStyle(
                                    color: Color(0xff64748b),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusPill(
                            label: enumLabel(commissionStatuses, row.status),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _WalletMini extends StatelessWidget {
  const _WalletMini({
    required this.label,
    required this.value,
    required this.textColor,
  });

  final String label;
  final String value;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xffcbd5e1),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
