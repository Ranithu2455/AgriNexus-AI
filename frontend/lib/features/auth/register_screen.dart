import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/api/api_exception.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/routes.dart';
import '../../shared/state/auth_provider.dart';
import '../../shared/widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
      await context.read<AuthProvider>().register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message.isNotEmpty ? e.message : t.registrationFailed);
    } catch (_) {
      setState(() => _errorMessage = t.registrationFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.register)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  controller: _fullNameController,
                  decoration: InputDecoration(labelText: t.fullName, border: const OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().length < 2) ? t.requiredField : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: t.email, border: const OutlineInputBorder()),
                  validator: (v) => (v == null || !v.contains('@')) ? t.requiredField : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: t.phone, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: t.password, border: const OutlineInputBorder()),
                  validator: (v) => (v == null || v.length < 8) ? t.requiredField : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: t.register, onPressed: _submit, loading: _loading),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.alreadyHaveAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
