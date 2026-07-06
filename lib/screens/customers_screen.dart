import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/models/customer.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/widgets/empty_state.dart';
import 'package:real_estate_crm_sales/widgets/sales_card.dart';
import 'package:real_estate_crm_sales/widgets/screen_frame.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late Future<List<Customer>> customers;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    customers = apiClient.getCustomers().then((list) {
      debugPrint('[Customers] loaded ${list.length} records');
      return list;
    }).catchError((e) {
      debugPrint('[Customers] error: $e');
      throw e;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'My Customers',
      subtitle: 'PROFILE LIST',
      action: IconButton.filledTonal(
        onPressed: () => setState(_load),
        icon: const Icon(Icons.refresh),
      ),
      child: FutureBuilder<List<Customer>>(
        future: customers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                heightFactor: 8, child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('[Customers] build error: ${snapshot.error}');
            return Center(
              heightFactor: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => setState(_load),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? [];
          debugPrint('[Customers] rendering ${data.length} items');
          if (data.isEmpty) {
            return const EmptyState(text: 'No customer profiles yet.');
          }

          return Column(
            children: [
              for (final customer in data) ...[
                SalesCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xff0f766e),
                      child: Text(
                          customer.name.isEmpty ? 'C' : customer.name[0],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900)),
                    ),
                    title: Text(customer.name,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.phone),
                        if (customer.email != null && customer.email!.isNotEmpty)
                          Text(customer.email!),
                        Text('Lead #${customer.leadId ?? '-'}'),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Text(customer.paymentStatus,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xff0f766e))),
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
