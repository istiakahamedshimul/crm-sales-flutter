import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> callPhone(BuildContext context, String phone) async {
  await _launch(context, Uri(scheme: 'tel', path: phone.trim()), 'phone');
}

Future<void> openWhatsApp(BuildContext context, String phone) async {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) digits = '88$digits';
  await _launch(
    context,
    Uri.parse('https://wa.me/$digits'),
    'WhatsApp',
  );
}

Future<void> _launch(BuildContext context, Uri uri, String target) async {
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _showError(context, 'Could not open $target.');
    }
  } catch (_) {
    if (context.mounted) _showError(context, 'Could not open $target.');
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
