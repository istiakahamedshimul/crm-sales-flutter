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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LoginHeader(),
                    const SizedBox(height: 18),
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
    setState(() {
      loading = true;
      error = '';
    });

    try {
      await apiClient.login(email.text, password.text);
      await oneSignalService.login('crm-user-${apiClient.userId}');
      if (!mounted) return;
      final initialIndex =
          oneSignalService.consumeAssignedLeadsNavigation() ? 1 : 0;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => HomeScreen(initialIndex: initialIndex)),
      );
    } catch (exception) {
      setState(
          () => error = 'Login failed. Start backend and check credentials.');
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff0f766e), Color(0xff111827)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0f766e).withOpacity(0.24),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                ),
                child: const Icon(Icons.apartment_rounded,
                    color: Colors.white, size: 30),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Field Sales',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            'Sales Workspace',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Assigned leads, follow-up proof, collections, invoices, and commission in one focused app.',
            style: TextStyle(
                color: Color(0xffdbe7e6),
                height: 1.5,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(child: _HeroStat(value: '24/7', label: 'Access')),
              SizedBox(width: 10),
              Expanded(child: _HeroStat(value: 'MVP', label: 'Ready')),
              SizedBox(width: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Color(0xffcbd5e1),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffdfe6eb)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Welcome back',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Sign in to continue your daily sales work.',
              style: TextStyle(
                  color: Color(0xff667085), fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.password_rounded),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: loading ? null : onSubmit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(loading ? 'Signing in...' : 'Enter Workspace'),
                if (!loading) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ],
            ),
          ),
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                error,
                style: const TextStyle(
                    color: Color(0xffb42318), fontWeight: FontWeight.w800),
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
        Icon(Icons.verified_user_outlined, size: 18, color: Color(0xff667085)),
        SizedBox(width: 8),
        Text('Admin-assigned leads only',
            style: TextStyle(
                color: Color(0xff667085), fontWeight: FontWeight.w800)),
      ],
    );
  }
}
