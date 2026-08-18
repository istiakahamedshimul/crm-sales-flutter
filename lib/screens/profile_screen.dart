import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/screens/login_screen.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/services/biometric_auth_service.dart';
import 'package:real_estate_crm_sales/services/one_signal_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  bool loading = true;
  bool biometricAvailable = false;
  bool biometricEnabled = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        apiClient.getProfile(),
        biometricAuthService.isAvailable,
        biometricAuthService.isEnabled,
      ]);
      if (!mounted) return;
      setState(() {
        profile = results[0] as Map<String, dynamic>;
        biometricAvailable = results[1] as bool;
        biometricEnabled = results[2] as bool;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red)),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        const CircleAvatar(radius: 36, child: Icon(Icons.person_rounded, size: 38)),
                        const SizedBox(height: 12),
                        Text(profile?['fullName']?.toString() ?? '', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(profile?['email']?.toString() ?? '', style: const TextStyle(color: Color(0xff64748b))),
                        const SizedBox(height: 4),
                        Text(profile?['designation']?.toString() ?? 'Sales Executive', style: const TextStyle(color: Color(0xff0f766e), fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(profile?['role']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(child: Column(children: [
                    ListTile(
                      leading: const Icon(Icons.lock_reset_rounded),
                      title: const Text('Change password'),
                      subtitle: const Text('Update your account password'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _showChangePassword,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint_rounded),
                      title: const Text('Fingerprint sign-in'),
                      subtitle: Text(biometricAvailable
                          ? 'Use this device’s enrolled fingerprint after logout'
                          : 'Fingerprint authentication is unavailable on this device'),
                      value: biometricEnabled,
                      onChanged: biometricAvailable ? _toggleBiometric : null,
                    ),
                  ])),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log out'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<String?> _askPassword(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, obscureText: true, autofocus: true, decoration: const InputDecoration(labelText: 'Current password')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Continue')),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (!enabled) {
      await biometricAuthService.disable();
      if (mounted) setState(() => biometricEnabled = false);
      return;
    }
    final password = await _askPassword('Enable fingerprint sign-in');
    if (password == null || password.isEmpty || profile == null) return;
    try {
      final email = profile!['email'].toString();
      await apiClient.login(email, password);
      await biometricAuthService.enable(email: email, password: password);
      if (mounted) setState(() => biometricEnabled = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _showChangePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
          const SizedBox(height: 12),
          TextField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
          const SizedBox(height: 12),
          TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update')),
        ],
      ),
    );
    if (submitted == true && mounted) {
      if (next.text.length < 8 || next.text != confirm.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords must match and contain at least 8 characters.')));
      } else {
        try {
          await apiClient.changePassword(currentPassword: current.text, newPassword: next.text);
          await biometricAuthService.updatePassword(next.text);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully.')));
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
        }
      }
    }
    current.dispose(); next.dispose(); confirm.dispose();
  }

  Future<void> _logout() async {
    await apiClient.clearSession();
    await oneSignalService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }
}
