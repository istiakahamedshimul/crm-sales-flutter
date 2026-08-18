import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';

enum _Period { monthly, yearly, overall, custom }

class SalesPerformanceScreen extends StatefulWidget {
  const SalesPerformanceScreen({super.key});
  @override State<SalesPerformanceScreen> createState() => _SalesPerformanceScreenState();
}

class _SalesPerformanceScreenState extends State<SalesPerformanceScreen> {
  _Period period = _Period.monthly;
  late DateTime from;
  late DateTime to;
  Future<Map<String, dynamic>>? report;

  @override void initState() { super.initState(); _apply(_Period.monthly); }

  void _apply(_Period value) {
    final now = DateTime.now(); period = value;
    if (value == _Period.monthly) { from = DateTime(now.year, now.month, 1); to = DateTime(now.year, now.month + 1, 0); }
    if (value == _Period.yearly) { from = DateTime(now.year, 1, 1); to = DateTime(now.year, 12, 31); }
    if (value == _Period.overall) { from = DateTime(2020, 1, 1); to = now; }
    report = apiClient.getSalesPerformance(from, to);
  }

  Future<void> _custom() async {
    final range = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)), initialDateRange: DateTimeRange(start: from, end: to));
    if (range == null) return;
    setState(() { period = _Period.custom; from = range.start; to = range.end; report = apiClient.getSalesPerformance(from, to); });
  }

  String _money(dynamic value) => NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0).format((value as num?) ?? 0);
  Widget _metric(String label, String value, IconData icon, Color color) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const SizedBox(height: 10), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: Color(0xff64748b), fontSize: 11, fontWeight: FontWeight.w700))])));

  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Performance Report')), body: Column(children: [
    Padding(padding: const EdgeInsets.all(12), child: Column(children: [Wrap(spacing: 7, children: _Period.values.map((value) => ChoiceChip(label: Text(value.name[0].toUpperCase() + value.name.substring(1)), selected: period == value, onSelected: (_) => value == _Period.custom ? _custom() : setState(() => _apply(value)))).toList()), const SizedBox(height: 8), Row(children: [Expanded(child: Text('${DateFormat('dd MMM yyyy').format(from)} — ${DateFormat('dd MMM yyyy').format(to)}', style: const TextStyle(fontWeight: FontWeight.w700))), IconButton(onPressed: _custom, icon: const Icon(Icons.date_range))])])),
    Expanded(child: FutureBuilder<Map<String, dynamic>>(future: report, builder: (context, snapshot) {
      if (!snapshot.hasData) return Center(child: snapshot.hasError ? Text('${snapshot.error}') : const CircularProgressIndicator());
      final data = snapshot.data!; final months = (data['months'] as List).cast<Map<String, dynamic>>();
      return ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 24), children: [GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.55, children: [_metric('Assigned Leads', '${data['assignedLeads']}', Icons.person_search, Colors.blue), _metric('Booked Clients / Win', '${data['bookedClients']}', Icons.emoji_events, Colors.teal), _metric('Collection', _money(data['totalCollection']), Icons.payments, Colors.orange), _metric('Commission', _money(data['totalCommission']), Icons.workspace_premium, Colors.purple)]), const SizedBox(height: 10), const Text('Monthly Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), ...months.map((row) => Card(child: ExpansionTile(title: Text(DateFormat('MMMM yyyy').format(DateTime.parse('${row['month']}')), style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('Win ${row['wins']} • Lost ${row['lost']} • Collection ${_money(row['collectionAchieved'])}'), children: [ListTile(title: const Text('Target units'), trailing: Text('${row['unitsAchieved']} / ${row['unitTarget']}')), ListTile(title: const Text('Unit shortage/winage'), trailing: Text('${(row['unitVariance'] as num) >= 0 ? '+' : ''}${row['unitVariance']}')), ListTile(title: const Text('Collection target'), trailing: Text(_money(row['collectionTarget']))), ListTile(title: const Text('Collection shortage/winage'), trailing: Text('${(row['collectionVariance'] as num) >= 0 ? '+' : '-'}${_money((row['collectionVariance'] as num).abs())}')), ListTile(title: const Text('Commission'), trailing: Text(_money(row['commission']))) ]))) ]);
    }))
  ]));
}
