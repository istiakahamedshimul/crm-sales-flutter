import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/models/follow_up.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/shared/crm_format.dart';
import 'package:real_estate_crm_sales/widgets/empty_state.dart';
import 'package:real_estate_crm_sales/widgets/sales_card.dart';
import 'package:real_estate_crm_sales/widgets/screen_frame.dart';

class FollowUpsScreen extends StatefulWidget {
  const FollowUpsScreen({super.key});

  @override
  State<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends State<FollowUpsScreen> {
  late Future<List<FollowUp>> followUps = apiClient.getFollowUps();

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Follow-up History',
      subtitle: 'ACTIVITY LOG',
      action: IconButton.filledTonal(
        onPressed: () => setState(() => followUps = apiClient.getFollowUps()),
        icon: const Icon(Icons.refresh),
      ),
      child: FutureBuilder<List<FollowUp>>(
        future: followUps,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                heightFactor: 8, child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const EmptyState(
                text: 'No follow-up updates submitted yet.');
          }

          return Column(
            children: [
              for (final item in data) ...[
                SalesCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.lead,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 17),
                            ),
                          ),
                          StatusPill(
                              label: enumLabel(followUpTypes, item.type)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(item.summary),
                      if (item.customerResponse != null &&
                          item.customerResponse!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.customerResponse!,
                          style: const TextStyle(
                              color: Color(0xff667085),
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        'Next: ${shortDate(item.nextFollowUpAt)}',
                        style: const TextStyle(
                            color: Color(0xffb54708),
                            fontWeight: FontWeight.w800),
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
}
