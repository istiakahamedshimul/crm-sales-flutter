import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/models/follow_up.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/services/app_events.dart';
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
      debugPrint('[FollowUpsScreen] Live auto-reloading follow-ups data...');
      setState(() => followUps = apiClient.getFollowUps());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Follow-up Logs',
      subtitle: 'INTERACTION HISTORY',
      action: IconButton.filledTonal(
        onPressed: () => setState(() => followUps = apiClient.getFollowUps()),
        icon: const Icon(Icons.refresh_rounded, size: 20),
      ),
      child: FutureBuilder<List<FollowUp>>(
        future: followUps,
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
                    onPressed: () => setState(() => followUps = apiClient.getFollowUps()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const EmptyState(
              text: 'No follow-up updates submitted yet. Log follow-ups on your Leads tab.',
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = data[index];
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
                            color: const Color(0xfff1f5f9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _resolveTypeIcon(item.type),
                            color: const Color(0xff0f766e),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.lead,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xff0f172a),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Activity Logged',
                                style: TextStyle(
                                  color: Color(0xff94a3b8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusPill(label: enumLabel(followUpTypes, item.type)),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xfff1f5f9)),
                    const Text(
                      'DISCUSSION SUMMARY',
                      style: TextStyle(
                        color: Color(0xff94a3b8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.summary.isNotEmpty ? item.summary : 'No summary provided.',
                      style: const TextStyle(
                        color: Color(0xff334155),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    if (item.customerResponse != null && item.customerResponse!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'CLIENT RESPONSE',
                        style: TextStyle(
                          color: Color(0xff94a3b8),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xfff8fafc),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xfff1f5f9)),
                        ),
                        child: Text(
                          '"${item.customerResponse!}"',
                          style: const TextStyle(
                            color: Color(0xff475569),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Divider(height: 24, color: Color(0xfff1f5f9)),
                    Row(
                      children: [
                        const Icon(Icons.alarm_on_rounded, size: 16, color: Color(0xffb45309)),
                        const SizedBox(width: 6),
                        Text(
                          'Next Contact: ${shortDate(item.nextFollowUpAt)}',
                          style: const TextStyle(
                            color: Color(0xffb45309),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
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
    );
  }

  IconData _resolveTypeIcon(Object? typeObj) {
    final type = typeObj is int ? typeObj : int.tryParse(typeObj?.toString() ?? '') ?? 0;
    switch (type) {
      case 0: // WhatsApp
        return Icons.chat_bubble_outline_rounded;
      case 1: // Call
        return Icons.call_rounded;
      case 2: // Facebook
        return Icons.facebook_rounded;
      case 3: // Meeting
        return Icons.people_outline_rounded;
      case 4: // Office
        return Icons.business_rounded;
      case 5: // Site Visit
        return Icons.location_on_outlined;
      case 6: // SMS
        return Icons.textsms_outlined;
      case 7: // Email
        return Icons.mail_outline_rounded;
      default:
        return Icons.notes_rounded;
    }
  }
}
