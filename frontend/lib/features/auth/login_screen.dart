import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/api/api_exception.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/routes.dart';
import '../../shared/state/auth_provider.dart';
import '../../shared/widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthProvider>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.isUnauthorized ? t.loginFailed : e.message);
    } catch (_) {
      setState(() => _errorMessage = t.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.agriculture, size: 64, color: Colors.green),
                  const SizedBox(height: 12),
                  Text(
                    t.appTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: t.email, border: const OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? t.requiredField : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: t.password, border: const OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? t.requiredField : null,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(label: t.login, onPressed: _submit, loading: _loading),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.register),
                    child: Text(t.dontHaveAccount),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
