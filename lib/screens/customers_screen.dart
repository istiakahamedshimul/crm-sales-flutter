import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/models/customer.dart';
import 'package:real_estate_crm_sales/models/project.dart';
import 'package:real_estate_crm_sales/screens/payments_screen.dart';
import 'package:real_estate_crm_sales/screens/vehicle_bookings_screen.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/services/app_events.dart';
import 'package:real_estate_crm_sales/widgets/empty_state.dart';
import 'package:real_estate_crm_sales/widgets/sales_card.dart';
import 'package:real_estate_crm_sales/widgets/screen_frame.dart';
import 'package:real_estate_crm_sales/shared/contact_actions.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Color(0xfff8fafc),
        body: SafeArea(
          child: Column(
            children: [
              Material(
                color: Colors.white,
                elevation: 0.5,
                child: TabBar(
                  isScrollable: false,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.contacts_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Clients', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Pay', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Visits', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                  indicatorColor: Color(0xff0f766e),
                  labelColor: Color(0xff0f766e),
                  unselectedLabelColor: Color(0xff64748b),
                  indicatorSize: TabBarIndicatorSize.tab,
                ),
              ),
              Expanded(
                child: TabBarView(
                  physics: NeverScrollableScrollPhysics(), // Taps switch pages, swiping switches tabs in main PageView
                  children: [
                    ActiveCustomersTabContent(),
                    PaymentsScreen(),
                    VehicleBookingsScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActiveCustomersTabContent extends StatefulWidget {
  const ActiveCustomersTabContent({super.key});

  @override
  State<ActiveCustomersTabContent> createState() => _ActiveCustomersTabContentState();
}

class _ActiveCustomersTabContentState extends State<ActiveCustomersTabContent> {
  late Future<List<Customer>> customers;

  @override
  void initState() {
    super.initState();
    _load();
    AppEvents.instance.addListener(_onAppReload);
  }

  @override
  void dispose() {
    AppEvents.instance.removeListener(_onAppReload);
    super.dispose();
  }

  void _onAppReload() {
    if (mounted) {
      debugPrint('[CustomersScreen] Live auto-reloading customer data...');
      setState(_load);
    }
  }

  void _load() {
    customers = apiClient.getBookedCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Booked Clients',
      subtitle: 'CLIENT PORTFOLIO',
      action: IconButton.filledTonal(
        onPressed: () => setState(_load),
        icon: const Icon(Icons.refresh_rounded, size: 20),
      ),
      child: FutureBuilder<List<Customer>>(
        future: customers,
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
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(_load),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const EmptyState(
              text: 'No booked customers yet. Booked clients appear automatically.',
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final customer = data[index];
              return _CustomerCard(
                customer: customer,
                onEditProject: () => _editProject(customer),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editProject(Customer customer) async {
    try {
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
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) {
            final types = projects
                .where((p) => subgroupId == null || p.subGroupId == subgroupId)
                .map((p) => p.type)
                .toSet()
                .toList()
              ..sort();
            final filtered = projects
                .where((p) =>
                    (subgroupId == null || p.subGroupId == subgroupId) &&
                    (type == null || p.type == type))
                .toList();
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Update Customer Project',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xff0f172a),
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context, false),
                      )
                    ],
                  ),
                  Text(
                    customer.name,
                    style: const TextStyle(
                      color: Color(0xff64748b),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: subgroupId,
                    decoration: const InputDecoration(
                      labelText: 'Subgroup / Company',
                    ),
                    items: [
                      for (final group in subgroups)
                        DropdownMenuItem(value: group.id, child: Text(group.name))
                    ],
                    onChanged: (value) => setSheetState(() {
                      subgroupId = value;
                      type = null;
                      projectId = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: types.contains(type) ? type : null,
                    decoration: const InputDecoration(labelText: 'Project Property Type'),
                    items: [
                      for (final value in types)
                        DropdownMenuItem(
                          value: value,
                          child: Text(_projectType(value)),
                        )
                    ],
                    onChanged: subgroupId == null
                        ? null
                        : (value) => setSheetState(() {
                              type = value;
                              projectId = null;
                            }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: filtered.any((p) => p.id == projectId) ? projectId : null,
                    decoration: const InputDecoration(labelText: 'Specific Property Unit'),
                    items: [
                      for (final project in filtered)
                        DropdownMenuItem(
                          value: project.id,
                          child: Text(project.name, overflow: TextOverflow.ellipsis),
                        )
                    ],
                    onChanged: type == null
                        ? null
                        : (value) => setSheetState(() => projectId = value),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                      ),
                    ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: projectId == null
                        ? null
                        : () async {
                            try {
                              await apiClient.updateCustomerProject(
                                customer.id,
                                projectId,
                              );
                              if (context.mounted) Navigator.pop(context, true);
                            } catch (e) {
                              setSheetState(() => error =
                                  e.toString().replaceFirst('Exception: ', ''));
                            }
                          },
                    child: const Text('Save Assigned Project'),
                  ),
                ],
              ),
            );
          },
        ),
      );
      if (saved == true && mounted) {
        AppEvents.instance.notifyReload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  static String _projectType(int value) => const [
        'Apartment',
        'Flat',
        'Plot',
        'Land',
        'Commercial Space',
        'Shop',
        'Office Space'
      ][value];
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.onEditProject,
  });

  final Customer customer;
  final VoidCallback onEditProject;

  @override
  Widget build(BuildContext context) {
    final hasProject = customer.project != null;
    final projectText = hasProject
        ? '${customer.subGroup ?? ''}${customer.subGroup == null ? '' : ' • '}${customer.project}'
        : 'No project assigned';

    return SalesCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xff0f766e), Color(0xff115e59)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  customer.name.isEmpty ? 'C' : customer.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xff0f172a),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone_iphone_rounded, size: 12, color: Color(0xff64748b)),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone,
                          style: const TextStyle(
                            color: Color(0xff64748b),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Update Unit',
                child: IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  onPressed: onEditProject,
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xfff1f5f9)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.apartment_rounded, size: 16, color: Color(0xff64748b)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  projectText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasProject ? const Color(0xff334155) : const Color(0xff94a3b8),
                    fontWeight: hasProject ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => callPhone(context, customer.phone),
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text('Call Client'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
               Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => openWhatsApp(context, customer.phone),
                  icon: const WhatsAppIcon(size: 16), // Custom branded WhatsApp icon widget
                  label: const Text('WhatsApp'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
