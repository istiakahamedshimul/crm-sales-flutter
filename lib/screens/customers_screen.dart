import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/models/customer.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/models/project.dart';
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
                        Text(customer.project == null
                            ? 'No project selected'
                            : '${customer.subGroup} - ${customer.project}'),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip: 'Update customer project',
                      icon: const Icon(Icons.edit_location_alt_outlined),
                      onPressed: () => _editProject(customer),
                    ),
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

  Future<void> _editProject(Customer customer) async {
    final selections = await Future.wait([
      apiClient.getSubGroups(),
      apiClient.getProjects(),
    ]);
    if (!mounted) return;
    final subgroups = selections[0].cast<ProjectSubGroup>();
    final projects = selections[1].cast<CrmProject>();
    var subgroupId = customer.subGroupId;
    var type = customer.projectType;
    var projectId = customer.projectId;
    String? error;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) {
        final types = projects
            .where((p) => subgroupId == null || p.subGroupId == subgroupId)
            .map((p) => p.type)
            .toSet()
            .toList()..sort();
        final filtered = projects.where((p) =>
            (subgroupId == null || p.subGroupId == subgroupId) &&
            (type == null || p.type == type)).toList();
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Update ${customer.name} project', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: subgroupId,
              decoration: const InputDecoration(labelText: 'Subgroup (Real Capital Group)'),
              items: [for (final group in subgroups) DropdownMenuItem(value: group.id, child: Text(group.name))],
              onChanged: (value) => setSheetState(() { subgroupId = value; type = null; projectId = null; }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: types.contains(type) ? type : null,
              decoration: const InputDecoration(labelText: 'Project type'),
              items: [for (final value in types) DropdownMenuItem(value: value, child: Text(_projectType(value)))],
              onChanged: subgroupId == null ? null : (value) => setSheetState(() { type = value; projectId = null; }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: filtered.any((p) => p.id == projectId) ? projectId : null,
              decoration: const InputDecoration(labelText: 'Project'),
              items: [for (final project in filtered) DropdownMenuItem(value: project.id, child: Text(project.name))],
              onChanged: type == null ? null : (value) => setSheetState(() => projectId = value),
            ),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: projectId == null ? null : () async {
                try {
                  await apiClient.updateCustomerProject(customer.id, projectId);
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  setSheetState(() => error = e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Save project'),
            )),
          ]),
        );
      }),
    );
    if (saved == true && mounted) setState(_load);
  }

  static String _projectType(int value) => const [
    'Apartment', 'Flat', 'Plot', 'Land', 'Commercial Space', 'Shop', 'Office Space'
  ][value];
}
