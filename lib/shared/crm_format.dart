import 'package:intl/intl.dart';

const leadStatuses = [
  'New',
  'Assigned',
  'Contacted',
  'Interested',
  'Follow-up',
  'Site Visit',
  'Visited',
  'Negotiation',
  'Proposal',
  'Booked',
  'Lost',
  'Not Interested',
];

const projectTypes = [
  'Apartment', 'Flat', 'Plot', 'Land', 'Commercial Space', 'Shop', 'Office Space' , 'Hospital', 'Hotel', 'Resort'
];
const followUpTypes = [
  'WhatsApp',
  'Call',
  'Facebook',
  'Meeting',
  'Office',
  'Site Visit',
  'SMS',
  'Email',
  'Other'
];
const paymentStatuses = ['Pending', 'Approved', 'Rejected'];
const commissionStatuses = ['Pending', 'Approved', 'Rejected', 'Paid', 'Hold'];

String enumLabel(List<String> labels, Object? value) {
  final index = value is int ? value : int.tryParse(value?.toString() ?? '');
  if (index == null || index < 0 || index >= labels.length) return '-';
  return labels[index];
}

String money(num value) {
  return NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 0)
      .format(value);
}

String shortDate(String? value) {
  if (value == null || value.isEmpty) return '-';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return '-';
  return DateFormat('MMM d, yyyy').format(parsed.toLocal());
}
