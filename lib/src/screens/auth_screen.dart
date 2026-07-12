import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/screens/forgot_password_screen.dart';
import 'package:lookup_user/src/services/api_service.dart';
import 'package:lookup_user/src/services/auth_service.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';

/// Acceso: un único formulario centrado, limpio y directo.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _careerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isRegistering = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthService>();
      if (auth.consumePasswordChangedNotice()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('settings.password.updated'))),
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _careerController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _error = null);
    final auth = context.read<AuthService>();

    try {
      final success = _isRegistering
          ? await auth.register(
              nombreCompleto: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              carrera: _careerController.text,
              telefono: _phoneController.text,
              ciudad: _cityController.text,
            )
          : await auth.login(_emailController.text, _passwordController.text);

      if (!mounted || !success) return;
      final cuentaId = auth.cuentaId;
      if (cuentaId != null) {
        await context.read<LookUpDataService>().refresh(cuentaId);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = context.tr('common.error.connection'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark(size: 64, mini: false)),
                    const SizedBox(height: 26),
                    Text(
                      _isRegistering
                          ? context.t('auth.register.title')
                          : context.t('auth.login.title'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isRegistering
                          ? context.t('auth.register.subtitle')
                          : context.t('auth.login.subtitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.inkMuted, height: 1.4),
                    ),
                    const SizedBox(height: 26),
                    if (_isRegistering) ...[
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.t('auth.name'),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (value) => requiredField(
                          value,
                          context.tr('auth.name.required'),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: context.t('auth.email'),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        final valid = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(email);
                        if (!valid) return context.tr('auth.email.invalid');
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      onFieldSubmitted: (_) =>
                          auth.isLoading ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: context.t('auth.password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        helperText: _isRegistering
                            ? context.t('auth.password.hint')
                            : null,
                        helperMaxLines: 2,
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (_isRegistering) {
                          return strongPasswordT(context, value);
                        }
                        if (value == null || value.length < 8) {
                          return context.tr('auth.password.short');
                        }
                        return null;
                      },
                    ),
                    if (!_isRegistering)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                ),
                          child: Text(
                            context.t('auth.forgot'),
                            style: TextStyle(
                              fontSize: 13,
                              color: c.inkMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    if (_isRegistering) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _careerController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.t('auth.career'),
                          prefixIcon: const Icon(Icons.school_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.t('auth.phone'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: context.t('auth.city'),
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (_error != null) ErrorBanner(message: _error!),
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isRegistering
                                  ? context.t('auth.register')
                                  : context.t('auth.login'),
                            ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: auth.isLoading
                          ? null
                          : () => setState(() {
                              _isRegistering = !_isRegistering;
                              _error = null;
                            }),
                      child: Text(
                        _isRegistering
                            ? context.t('auth.have_account')
                            : context.t('auth.create_account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
