import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:real_estate_crm_sales/models/app_notification.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/screens/customers_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _items;
  @override void initState() { super.initState(); _reload(); }
  void _reload() => _items = apiClient.getNotifications();

  Future<void> _markAll() async { await apiClient.markAllNotificationsRead(); if (mounted) setState(_reload); }
  Future<void> _open(AppNotification item) async {
    if (!item.isRead) await apiClient.markNotificationRead(item.id);
    if (!mounted) return;
    setState(_reload);
    if (item.customerId != null) {
      final customers = await apiClient.getBookedCustomers();
      final matches = customers.where((x) => x.id == item.customerId);
      if (matches.isNotEmpty && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerFinancialScreen(customer: matches.first)));
      }
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications'), actions: [TextButton(onPressed: _markAll, child: const Text('Read all'))]),
    body: RefreshIndicator(onRefresh: () async { setState(_reload); await _items; }, child: FutureBuilder<List<AppNotification>>(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text('Could not load notifications.\n${snapshot.error}'))]);
        final items = snapshot.data ?? [];
        if (items.isEmpty) return ListView(children: const [Padding(padding: EdgeInsets.all(48), child: Center(child: Text('No notifications yet')))]);
        return ListView.separated(padding: const EdgeInsets.all(12), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, index) {
          final item = items[index];
          return Card(color: item.isRead ? Colors.white : const Color(0xffecfdf5), child: ListTile(
            leading: CircleAvatar(child: Icon(item.type.toLowerCase().contains('overdue') ? Icons.warning_amber_rounded : Icons.notifications_outlined)),
            title: Text(item.title, style: TextStyle(fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w900)),
            subtitle: Text('${item.message}\n${DateFormat('dd MMM yyyy, h:mm a').format(item.createdAt.toLocal())}'),
            isThreeLine: true, trailing: item.isRead ? null : const CircleAvatar(radius: 5), onTap: () => _open(item),
          ));
        });
      },
    )),
  );
}
