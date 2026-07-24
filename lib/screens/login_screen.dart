import 'package:flutter/material.dart';
import 'package:real_estate_crm_sales/config/app_config.dart';
import 'package:real_estate_crm_sales/screens/home_screen.dart';
import 'package:real_estate_crm_sales/services/api_client.dart';
import 'package:real_estate_crm_sales/services/one_signal_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(text: AppConfig.defaultEmail);
  final password = TextEditingController(text: AppConfig.defaultPassword);
  String error = '';
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LoginHeader(),
                    const SizedBox(height: 24),
                    _LoginForm(
                      email: email,
                      password: password,
                      loading: loading,
                      error: error,
                      onSubmit: login,
                    ),
                    const SizedBox(height: 24),
                    const _TrustStrip(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.trim().isEmpty) {
      setState(() => error = 'Please enter email and password.');
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      await apiClient.login(email.text.trim(), password.text.trim());
      await oneSignalService.login('crm-user-${apiClient.userId}');
      if (!mounted) return;
      final initialIndex =
          oneSignalService.consumeAssignedLeadsNavigation() ? 1 : 0;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(initialIndex: initialIndex),
        ),
      );
    } catch (exception) {
      setState(
        () => error = exception.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff0f766e), Color(0xff0f172a)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0f766e).withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Sales Connect',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Sales Workspace',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 28,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage assigned leads, upload follow-up logs, submit collection receipts, and track your wallet.',
            style: TextStyle(
              color: Color(0xffcbd5e1),
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(child: _HeroStat(value: 'Live', label: 'Sync')),
              SizedBox(width: 8),
              Expanded(child: _HeroStat(value: 'OneSignal', label: 'Alerts')),
              SizedBox(width: 8),
              Expanded(child: _HeroStat(value: 'JWT', label: 'Secure')),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff94a3b8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.email,
    required this.password,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController email;
  final TextEditingController password;
  final bool loading;
  final String error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xfff1f5f9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0f172a).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xff0f172a),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sign in to sync your active sales pipeline.',
            style: TextStyle(
              color: Color(0xff64748b),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: password,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => loading ? null : onSubmit(),
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : onSubmit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(loading ? 'Signing in...' : 'Sign In'),
                if (!loading) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ],
            ),
          ),
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xfffef2f2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xfffee2e2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xffef4444), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(
                          color: Color(0xffb91c1c),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, size: 16, color: Color(0xff64748b)),
        SizedBox(width: 6),
        Text(
          'Secured Workspace Client',
          style: TextStyle(
            color: Color(0xff64748b),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
