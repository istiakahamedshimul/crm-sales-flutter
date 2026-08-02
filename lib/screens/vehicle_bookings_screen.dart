import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/models/lead.dart';
import 'package:real_estate_crm_sales/models/vehicle_booking.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/services/app_events.dart';
import 'package:real_estate_crm_sales/widgets/empty_state.dart';
import 'package:real_estate_crm_sales/widgets/sales_card.dart';
import 'package:real_estate_crm_sales/widgets/screen_frame.dart';

class VehicleBookingsScreen extends StatefulWidget {
  const VehicleBookingsScreen({super.key});

  @override
  State<VehicleBookingsScreen> createState() => _VehicleBookingsScreenState();
}

class _VehicleBookingsScreenState extends State<VehicleBookingsScreen> {
  late Future<List<VehicleBooking>> bookings;

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
      debugPrint('[VehicleBookingsScreen] Live auto-reloading bookings data...');
      setState(() => _load());
    }
  }

  void _load() {
    bookings = apiClient.getVehicleBookings();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'Visits',
      subtitle: 'TRANSPORT REQUESTS',
      action: IconButton.filled(
        onPressed: _openForm,
        icon: const Icon(Icons.add, size: 20),
        tooltip: 'New visit request',
      ),
      child: FutureBuilder<List<VehicleBooking>>(
        future: bookings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              heightFactor: 6,
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const EmptyState(
              text: 'No visit requests yet. Tap the top + button to request transport.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryHeader(data),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildBookingCard(data[index]);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(List<VehicleBooking> data) {
    final pendingCount = data.where((x) => x.status == 0).length;
    final approvedCount = data.where((x) => x.status == 1).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xff0f766e), Color(0xff115e59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0f766e).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Visit Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pendingCount pending review · $approvedCount approved visits',
                  style: const TextStyle(
                    color: Color(0xffdbe7e6),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(VehicleBooking b) {
    return SalesCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xffe8f5f3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xff0f766e),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.customer,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Color(0xff0f172a),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      b.project,
                      style: const TextStyle(
                        color: Color(0xff64748b),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: _status(b.status),
                color: _statusColor(b.status),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xfff1f5f9)),
          _buildDetailRow(Icons.calendar_month_outlined, '${_date(b.visitDate)} at ${b.visitTime}'),
          _buildDetailRow(Icons.people_outline_rounded, '${b.personCount} visitors · ${b.purpose}'),
          _buildDetailRow(Icons.my_location_outlined, b.pickupPlace),
          if (b.vehicle?.isNotEmpty == true)
            _buildDetailRow(
              Icons.directions_car_filled_outlined,
              '${b.vehicle}${b.driver?.isNotEmpty == true ? ' (Driver: ${b.driver})' : ''}',
            ),
          if (b.adminRemarks?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xfffffbeb),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xfffef3c7)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xffd97706),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ADMIN REMARKS',
                          style: TextStyle(
                            color: Color(0xffb45309),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          b.adminRemarks!,
                          style: const TextStyle(
                            color: Color(0xff92400e),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xff64748b)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xff475569),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm() async {
    final now = DateTime.now();
    var date = DateTime(now.year, now.month, now.day).add(Duration(days: now.hour >= 19 ? 2 : 1));
    var time = const TimeOfDay(hour: 10, minute: 0);
    String purpose = 'Site Visit';
    int? leadId, projectId;
    String? error;
    bool saving = false;

    final pickup = TextEditingController();
    final persons = TextEditingController(text: '1');
    final additional = TextEditingController();

    try {
      final results = await Future.wait([
        apiClient.getLeads(),
        apiClient.getProjects(),
      ]);
      final leads = results[0] as List<Lead>;
      final projects = results[1] as List<dynamic>;
      if (!mounted) return;

      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => StatefulBuilder(
          builder: (context, setSheet) => Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xffcbd5e1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Request Visit',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xff0f172a),
                        ),
                  ),
                  const Text(
                    'Admin will review and assign transport details.',
                    style: TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Pipeline Lead',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    items: leads
                        .map((c) => DropdownMenuItem<int>(
                              value: c.id,
                              child: Text('${c.customerName} (${c.phone})', overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setSheet(() {
                      leadId = v;
                      final lead = leads.firstWhere((item) => item.id == v);
                      projectId = lead.projectId;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: projectId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Target Project',
                      prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                    ),
                    items: projects
                        .map((p) => DropdownMenuItem<int>(
                              value: p.id as int,
                              child: Text(p.name as String, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setSheet(() => projectId = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final first = DateTime.now().add(Duration(days: DateTime.now().hour >= 19 ? 2 : 1));
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: date,
                              firstDate: DateTime(first.year, first.month, first.day),
                              lastDate: first.add(const Duration(days: 365)),
                            );
                            if (picked != null) setSheet(() => date = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Visit Date'),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_date(date), style: const TextStyle(fontWeight: FontWeight.w700)),
                                const Icon(Icons.calendar_today_rounded, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: time);
                            if (picked != null) setSheet(() => time = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Visit Time'),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(time.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                                const Icon(Icons.schedule_rounded, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: persons,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Number of Visitors',
                      prefixIcon: Icon(Icons.group_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pickup,
                    decoration: const InputDecoration(
                      labelText: 'Pickup Location Address',
                      prefixIcon: Icon(Icons.place_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: purpose,
                    decoration: const InputDecoration(
                      labelText: 'Purpose of Visit',
                      prefixIcon: Icon(Icons.flag_outlined, size: 20),
                    ),
                    items: const ['Site Visit', 'Booking', 'Customer Meeting', 'Inspection']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheet(() => purpose = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: additional,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Additional Info / Remarks',
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final count = int.tryParse(persons.text);
                            if (leadId == null ||
                                projectId == null ||
                                count == null ||
                                count < 1 ||
                                pickup.text.trim().isEmpty) {
                              setSheet(() => error = 'Please complete all required fields.');
                              return;
                            }
                            setSheet(() {
                              saving = true;
                              error = null;
                            });
                            try {
                              await apiClient.createVehicleBooking(
                                leadId: leadId!,
                                projectId: projectId!,
                                visitDate: date,
                                visitTime: time,
                                personCount: count,
                                pickupPlace: pickup.text.trim(),
                                purpose: purpose,
                                additionalInformation: additional.text.trim(),
                              );
                              if (context.mounted) Navigator.pop(context, true);
                            } catch (e) {
                              setSheet(() {
                                saving = false;
                                error = e.toString().replaceFirst('Exception: ', '');
                              });
                            }
                          },
                    child: Text(saving ? 'Submitting Request...' : 'Submit Visit Request'),
                  )
                ],
              ),
            ),
          ),
        ),
      );

      if (saved == true && mounted) {
        AppEvents.instance.notifyReload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      pickup.dispose();
      persons.dispose();
      additional.dispose();
    }
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _status(int v) => const ['Pending', 'Approved', 'Rejected', 'Cancelled'][v];

  static Color _statusColor(int v) => const [
        Color(0xffd97706), // Amber for Pending
        Color(0xff0f766e), // Teal for Approved
        Color(0xffe11d48), // Rose for Rejected
        Color(0xff64748b)  // Slate for Cancelled
      ][v];
}
