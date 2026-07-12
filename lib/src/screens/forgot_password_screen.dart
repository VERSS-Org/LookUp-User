import 'package:flutter/material.dart';

import 'package:lookup_user/src/services/api_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';

/// Recuperación de contraseña en dos pasos: correo -> código + nueva clave.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = context.tr('auth.email.invalid'));
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.post('iam/recuperar-password', {
        'email': email,
      }, retryOnUnauthorized: false);
      if (!mounted) return;
      final codigoDev = response is Map ? response['codigo_dev'] : null;
      setState(() {
        _codeSent = true;
        _info = response is Map ? response['mensaje']?.toString() : null;
        // Sin servicio de correo, el backend en desarrollo devuelve el
        // código para poder completar el flujo localmente.
        if (codigoDev != null) {
          _codeController.text = codigoDev.toString();
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.tr('common.error.connection'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _api.post('iam/restablecer-password', {
        'email': _emailController.text.trim(),
        'codigo': _codeController.text.trim(),
        'password_nuevo': _passwordController.text,
      }, retryOnUnauthorized: false);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('reset.success'))));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.tr('common.error.connection'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('reset.title'))),
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
                    Icon(Icons.lock_reset_rounded, size: 44, color: c.brand),
                    const SizedBox(height: 14),
                    Text(
                      _codeSent
                          ? context.t('reset.step2.hint')
                          : context.t('reset.subtitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.inkMuted, height: 1.45),
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: _emailController,
                      enabled: !_codeSent && !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: context.t('auth.email'),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _codeController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: context.t('reset.code'),
                          hintText: context.t('reset.code.hint'),
                          prefixIcon: const Icon(Icons.pin_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().length != 6
                            ? context.tr('reset.code.hint')
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: context.t('reset.new_password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          helperText: context.t('auth.password.hint'),
                          helperMaxLines: 2,
                        ),
                        validator: (value) => strongPasswordT(context, value),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmController,
                        enabled: !_isLoading,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: context.t('reset.confirm_password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        validator: (value) => value != _passwordController.text
                            ? context.tr('reset.confirm.mismatch')
                            : null,
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (_error != null) ErrorBanner(message: _error!),
                    if (_info != null && _error == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _info!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.inkMuted, fontSize: 13),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_codeSent ? _submitReset : _requestCode),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _codeSent
                                  ? context.t('reset.submit')
                                  : context.t('reset.send_code'),
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
