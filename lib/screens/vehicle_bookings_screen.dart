import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/models/vehicle_booking.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
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
  }

  void _load() => bookings = apiClient.getVehicleBookings();

  @override
  Widget build(BuildContext context) => ScreenFrame(
        title: 'Vehicle Visits',
        subtitle: 'BOOKING REQUESTS',
        action: IconButton.filled(
          onPressed: _openBookingForm,
          icon: const Icon(Icons.add),
          tooltip: 'Book vehicle',
        ),
        child: FutureBuilder<List<VehicleBooking>>(
          future: bookings,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(heightFactor: 8, child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString().replaceFirst('Exception: ', '')));
            }
            final data = snapshot.data ?? [];
            if (data.isEmpty) return const EmptyState(text: 'No vehicle bookings yet.');
            return Column(children: [
              for (final booking in data) ...[
                SalesCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(_date(booking.visitDate), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
                    Chip(label: Text(_status(booking.status))),
                  ]),
                  Text('${booking.personCount} person${booking.personCount == 1 ? '' : 's'}'),
                  Text('Pickup: ${booking.pickupPlace}'),
                  Text('Visit: ${booking.visitPlace}'),
                  if (booking.adminRemarks?.isNotEmpty == true) Text('Admin: ${booking.adminRemarks}'),
                ])),
                const SizedBox(height: 12),
              ]
            ]);
          },
        ),
      );

  Future<void> _openBookingForm() async {
    final now = DateTime.now();
    final afterCutoff = now.hour >= 19;
    var visitDate = DateTime(now.year, now.month, now.day).add(Duration(days: afterCutoff ? 2 : 1));
    final visitPlace = TextEditingController();
    final pickupPlace = TextEditingController();
    final persons = TextEditingController(text: '1');
    String? error;
    var saving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Book vehicle for visit', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Next-day requests must be submitted before 7:00 PM local time.'),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Visit date'),
            subtitle: Text(_date(visitDate)),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final current = DateTime.now();
              final first = DateTime(current.year, current.month, current.day).add(
                  Duration(days: current.hour >= 19 ? 2 : 1));
              final picked = await showDatePicker(
                context: context,
                initialDate: visitDate.isBefore(first) ? first : visitDate,
                firstDate: first,
                lastDate: first.add(const Duration(days: 365)),
              );
              if (picked != null) setSheetState(() => visitDate = picked);
            },
          ),
          TextField(controller: persons, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Number of persons')),
          const SizedBox(height: 12),
          TextField(controller: pickupPlace, decoration: const InputDecoration(labelText: 'Pickup place')),
          const SizedBox(height: 12),
          TextField(controller: visitPlace, decoration: const InputDecoration(labelText: 'Visit place')),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: saving ? null : () async {
              final count = int.tryParse(persons.text);
              if (count == null || count < 1 || pickupPlace.text.trim().isEmpty || visitPlace.text.trim().isEmpty) {
                setSheetState(() => error = 'Enter a valid person count, pickup place, and visit place.');
                return;
              }
              setSheetState(() { saving = true; error = null; });
              try {
                await apiClient.createVehicleBooking(
                  visitDate: visitDate,
                  personCount: count,
                  visitPlace: visitPlace.text.trim(),
                  pickupPlace: pickupPlace.text.trim(),
                );
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                setSheetState(() { saving = false; error = e.toString().replaceFirst('Exception: ', ''); });
              }
            },
            child: Text(saving ? 'Submitting...' : 'Submit booking'),
          )),
        ])),
      )),
    );
    visitPlace.dispose();
    pickupPlace.dispose();
    persons.dispose();
    if (saved == true && mounted) setState(_load);
  }

  static String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  static String _status(int value) => const ['Pending', 'Approved', 'Rejected', 'Cancelled'][value];
}
