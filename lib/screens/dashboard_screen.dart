import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/models/customer.dart';
import 'package:real_estate_crm_sales/models/lead.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/services/app_events.dart';
import 'package:real_estate_crm_sales/shared/crm_format.dart';
import 'package:real_estate_crm_sales/shared/contact_actions.dart';
import 'package:real_estate_crm_sales/screens/login_screen.dart';
import 'package:real_estate_crm_sales/screens/sales_performance_screen.dart';
import 'package:real_estate_crm_sales/services/one_signal_service.dart';
import 'package:real_estate_crm_sales/services/location_tracking_service.dart';
import 'package:real_estate_crm_sales/widgets/sales_card.dart';
import 'package:real_estate_crm_sales/widgets/screen_frame.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> data = _load();
  bool _locationEnabled = true;
  bool _locationChanging = false;

  Future<_DashboardData> _load() async {
    final results = await Future.wait([
      apiClient.getProfile(),
      apiClient.getLeads(),
      apiClient.getBookedCustomers(),
      apiClient.getDashboardSummary(),
    ]);

    return _DashboardData(
      profile: results[0] as Map<String, dynamic>,
      leads: results[1] as List<Lead>,
      customers: results[2] as List<Customer>,
      totalOutstanding:
          ((results[3] as Map<String, dynamic>)['totalOutstanding'] as num?) ??
              0,
      currentTarget: (results[3] as Map<String, dynamic>)['currentTarget']
          as Map<String, dynamic>?,
    );
  }

  @override
  void initState() {
    super.initState();
    locationTrackingService.loadEnabled().then((value) {
      if (mounted) setState(() => _locationEnabled = value);
    });
    AppEvents.instance.addListener(_onAppReload);
  }

  Future<void> _setLocationTracking(bool enabled) async {
    setState(() {
      _locationEnabled = enabled;
      _locationChanging = true;
    });
    final saved = await locationTrackingService.setEnabled(enabled);
    if (!mounted) return;
    setState(() => _locationChanging = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(saved
            ? (enabled
                ? 'App location tracking turned on.'
                : 'App location tracking turned off.')
            : 'Could not save the location tracking setting. Please try again.')));
  }

  @override
  void dispose() {
    AppEvents.instance.removeListener(_onAppReload);
    super.dispose();
  }

  void _onAppReload() {
    if (mounted) {
      debugPrint('[DashboardScreen] Live auto-reloading dashboard data...');
      setState(() => data = _load());
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text(
            'Are you sure you want to sign out from your sales workspace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffe11d48)),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await locationTrackingService.stopAndUnschedule();
    await oneSignalService.logout();
    await apiClient.clearSession();
    if (!context.mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _showTargetHistory(BuildContext context) async {
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final rows = await apiClient.getTargetHistory();
      if (!context.mounted) return;
      Navigator.pop(context);
      await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (context) => SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Monthly Target Report',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 14),
                        if (rows.isEmpty)
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 28),
                              child: Center(
                                  child: Text(
                                      'No monthly targets have been set.')))
                        else
                          Flexible(
                              child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: rows.length,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (_, index) =>
                                      _TargetHistoryRow(row: rows[index]))),
                      ]))));
    } catch (error) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Today\'s Work',
      subtitle: 'SALES PIPELINE',
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SalesPerformanceScreen())),
            icon: const Icon(Icons.assessment_rounded, size: 20),
            tooltip: 'Filtered Performance',
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () => setState(() => data = _load()),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh Dashboard',
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded,
                color: Color(0xffe11d48), size: 20),
            tooltip: 'Log Out',
          ),
        ],
      ),
      child: FutureBuilder<_DashboardData>(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
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
                    onPressed: () => setState(() => data = _load()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final item = snapshot.data!;
          final totalOutstanding = item.totalOutstanding;

          final String userName =
              item.profile['fullName']?.toString() ?? 'Sales Executive';
          final String userEmail =
              item.profile['email']?.toString() ?? 'sales@crm.local';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium profile card & compact Location Tracking Toggle
              SalesCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xff0f766e), Color(0xff0d9488)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xff0f172a),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            userEmail,
                            style: const TextStyle(
                              color: Color(0xff64748b),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _locationEnabled
                            ? const Color(0xffeff6ff)
                            : const Color(0xfffff1f2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _locationEnabled
                              ? const Color(0xffdbeafe)
                              : const Color(0xffffe4e6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _locationEnabled
                                ? Icons.location_on_rounded
                                : Icons.location_off_rounded,
                            color: _locationEnabled
                                ? const Color(0xff2563eb)
                                : const Color(0xffe11d48),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _locationEnabled ? 'Tracking' : 'Off',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _locationEnabled
                                  ? const Color(0xff2563eb)
                                  : const Color(0xffe11d48),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Transform.scale(
                            scale: 0.7,
                            child: Switch.adaptive(
                              value: _locationEnabled,
                              onChanged: _locationChanging
                                  ? null
                                  : _setLocationTracking,
                              activeColor: const Color(0xff2563eb),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (item.currentTarget != null) ...[
                InkWell(
                  onTap: () => _showTargetHistory(context),
                  borderRadius: BorderRadius.circular(16),
                  child: SalesCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'This Month\'s Targets',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: Color(0xff0f172a),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showTargetHistory(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.history_rounded, size: 14),
                              label: const Text(
                                'History',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _TargetProgressTile(
                                label: 'Target Unit',
                                icon: Icons.flag_rounded,
                                achievedStr:
                                    '${item.currentTarget!['salesUnitsAchieved']}',
                                targetStr:
                                    '${item.currentTarget!['salesUnitTarget']}',
                                progress: ((item.currentTarget![
                                                'salesUnitTarget'] as num?) ??
                                            0) >
                                        0
                                    ? (((item.currentTarget![
                                                        'salesUnitsAchieved']
                                                    as num?) ??
                                                0) /
                                            ((item.currentTarget![
                                                        'salesUnitTarget']
                                                    as num?) ??
                                                0))
                                        .clamp(0.0, 1.0)
                                    : 0.0,
                                variance:
                                    (item.currentTarget!['salesUnitVariance']
                                            as num?) ??
                                        0,
                                moneyValue: false,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 1,
                              height: 52,
                              color: const Color(0xffe2e8f0),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _TargetProgressTile(
                                label: 'Collection',
                                icon: Icons.payments_rounded,
                                achievedStr: moneyCompact(
                                    (item.currentTarget!['collectionAchieved']
                                            as num?) ??
                                        0),
                                targetStr: moneyCompact(
                                    (item.currentTarget!['collectionTarget']
                                            as num?) ??
                                        0),
                                progress: ((item.currentTarget![
                                                'collectionTarget'] as num?) ??
                                            0) >
                                        0
                                    ? (((item.currentTarget![
                                                        'collectionAchieved']
                                                    as num?) ??
                                                0) /
                                            ((item.currentTarget![
                                                        'collectionTarget']
                                                    as num?) ??
                                                0))
                                        .clamp(0.0, 1.0)
                                    : 0.0,
                                variance:
                                    (item.currentTarget!['collectionVariance']
                                            as num?) ??
                                        0,
                                moneyValue: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _MetricTile(
                          label: 'Assigned Leads',
                          value: item.leads.length.toString(),
                          icon: Icons.person_search_rounded,
                          tileColor: const Color(0xff2563eb)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(
                          label: 'Booked Clients',
                          value: item.customers.length.toString(),
                          icon: Icons.people_alt_rounded,
                          tileColor: const Color(0xff0f766e)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _MetricTile(
                label: 'Collection',
                value: money(
                    (item.currentTarget?['collectionAchieved'] as num?) ?? 0),
                icon: Icons.payments_rounded,
                tileColor: const Color(0xffd97706),
              ),
              const SizedBox(height: 10),
              // Lead queue card with fast quick actions
              SalesCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Leads',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Color(0xff0f172a),
                          ),
                        ),
                        if (item.leads.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xffeff6ff),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${item.leads.length} total',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff2563eb),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (item.leads.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No assigned leads yet. Admin will distribute leads soon.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xff64748b),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: item.leads.take(4).length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Color(0xfff1f5f9), height: 10),
                        itemBuilder: (context, index) {
                          final lead = item.leads[index];
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lead.customerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Color(0xff0f172a),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      lead.phone,
                                      style: const TextStyle(
                                        color: Color(0xff64748b),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton.filledTonal(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    onPressed: () =>
                                        callPhone(context, lead.phone),
                                    icon: const Icon(Icons.call, size: 14),
                                    tooltip: 'Call client',
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton.filledTonal(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    onPressed: () =>
                                        openWhatsApp(context, lead.phone),
                                    icon: const WhatsAppIcon(size: 14),
                                    tooltip: 'WhatsApp client',
                                  ),
                                  const SizedBox(width: 6),
                                  StatusPill(
                                      label:
                                          enumLabel(leadStatuses, lead.status)),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tileColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tileColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfff1f5f9), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: tileColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: tileColor, size: 20),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xff0f172a),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff64748b),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetProgressTile extends StatelessWidget {
  const _TargetProgressTile({
    required this.label,
    required this.icon,
    required this.achievedStr,
    required this.targetStr,
    required this.progress,
    required this.variance,
    required this.moneyValue,
  });

  final String label;
  final IconData icon;
  final String achievedStr;
  final String targetStr;
  final double progress;
  final num variance;
  final bool moneyValue;

  @override
  Widget build(BuildContext context) {
    final over = variance >= 0;
    final progressPercent = (progress * 100).toStringAsFixed(0);
    final varianceColor =
        over ? const Color(0xff067647) : const Color(0xffb42318);
    final varianceBg = over ? const Color(0xffecfdf3) : const Color(0xfffef3f2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xff475569)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: Color(0xff1e293b),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$progressPercent%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xff0f766e),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$achievedStr / $targetStr',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xff64748b),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: BoxDecoration(
                color: varianceBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${over ? '+' : '-'}${moneyValue ? moneyCompact(variance.abs()) : variance.abs().toString()}',
                style: TextStyle(
                  color: varianceColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: const Color(0xfff1f5f9),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff0d9488)),
          ),
        ),
      ],
    );
  }
}

class _TargetHistoryRow extends StatelessWidget {
  const _TargetHistoryRow({required this.row});
  final Map<String, dynamic> row;
  @override
  Widget build(BuildContext context) {
    final unitVariance = (row['salesUnitVariance'] as num?) ?? 0;
    final collectionVariance = (row['collectionVariance'] as num?) ?? 0;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(shortDate(row['month']?.toString()),
              style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          _line(
              'Target Unit',
              '${row['salesUnitsAchieved']} / ${row['salesUnitTarget']} units',
              unitVariance,
              false),
          _line(
              'Collection',
              '${money((row['collectionAchieved'] as num?) ?? 0)} / ${money((row['collectionTarget'] as num?) ?? 0)}',
              collectionVariance,
              true)
        ]));
  }

  Widget _line(String label, String values, num variance, bool isMoney) =>
      Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            SizedBox(width: 82, child: Text(label)),
            Expanded(child: Text(values)),
            Text(
                '${variance >= 0 ? 'Over' : 'Short'} ${isMoney ? money(variance.abs()) : '${variance.abs()} units'}',
                style: TextStyle(
                    color: variance >= 0
                        ? const Color(0xff067647)
                        : const Color(0xffb42318),
                    fontWeight: FontWeight.w700))
          ]));
}

String moneyCompact(num value) {
  if (value >= 10000000) {
    return '৳${(value / 10000000).toStringAsFixed(1).replaceAll('.0', '')}Cr';
  } else if (value >= 100000) {
    return '৳${(value / 100000).toStringAsFixed(1).replaceAll('.0', '')}L';
  } else if (value >= 1000) {
    return '৳${(value / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
  }
  return '৳${value.toStringAsFixed(0)}';
}

class _DashboardData {
  const _DashboardData({
    required this.profile,
    required this.leads,
    required this.customers,
    required this.totalOutstanding,
    required this.currentTarget,
  });

  final Map<String, dynamic> profile;
  final List<Lead> leads;
  final List<Customer> customers;
  final num totalOutstanding;
  final Map<String, dynamic>? currentTarget;
}
