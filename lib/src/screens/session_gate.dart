import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/screens/app_shell.dart';
import 'package:lookup_user/src/screens/auth_screen.dart';
import 'package:lookup_user/src/services/auth_service.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';

/// Restaura la sesion guardada y decide entre login y la app autenticada.
class SessionGate extends StatefulWidget {
  const SessionGate({
    super.key,
    this.bootTimeout = const Duration(seconds: 20),
  });

  /// Límite de seguridad para restaurar la sesión y cargar los datos iniciales.
  /// Las solicitudes individuales también tienen timeout; este límite evita que
  /// cualquier dependencia inesperada deje el splash visible indefinidamente.
  final Duration bootTimeout;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  _BootState _bootState = _BootState.loading;
  String? _bootErrorKey;
  int _bootAttempt = 0;
  AuthService? _authService;
  bool? _wasAuthenticated;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    if (identical(auth, _authService)) return;
    _authService?.removeListener(_handleAuthChanged);
    _authService = auth;
    _wasAuthenticated = auth.isAuthenticated;
    auth.addListener(_handleAuthChanged);

    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !context.read<AuthService>().isAuthenticated) {
          context.read<LookUpDataService>().clear();
        }
      });
    }
  }

  void _handleAuthChanged() {
    final isAuthenticated = _authService?.isAuthenticated ?? false;
    final signedOut = _wasAuthenticated == true && !isAuthenticated;
    _wasAuthenticated = isAuthenticated;
    if (signedOut && mounted) {
      context.read<LookUpDataService>().clear();
    }
  }

  @override
  void dispose() {
    _authService?.removeListener(_handleAuthChanged);
    super.dispose();
  }

  Future<void> _boot() async {
    final attempt = ++_bootAttempt;
    if (_bootState != _BootState.loading && mounted) {
      setState(() {
        _bootState = _BootState.loading;
        _bootErrorKey = null;
      });
    }

    final auth = context.read<AuthService>();
    final data = context.read<LookUpDataService>();
    try {
      final restored = await auth.tryAutoLogin().timeout(widget.bootTimeout);
      final cuentaId = auth.cuentaId;
      if (restored && (cuentaId == null || cuentaId.isEmpty)) {
        throw StateError('La sesión restaurada no tiene una cuenta válida.');
      }

      if (!mounted || attempt != _bootAttempt) return;
      setState(() => _bootState = _BootState.ready);

      // Las vacantes, procesos y métricas son contenido secundario. Se cargan
      // dentro de la app y nunca retienen al usuario en el splash de sesión.
      if (restored && cuentaId != null) {
        unawaited(data.refresh(cuentaId));
      }
    } on TimeoutException {
      _showBootError(attempt, 'boot.error.timeout');
    } catch (_) {
      _showBootError(attempt, 'boot.error.connection');
    }
  }

  void _showBootError(int attempt, String messageKey) {
    if (!mounted || attempt != _bootAttempt) return;
    setState(() {
      _bootState = _BootState.failed;
      _bootErrorKey = messageKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_bootState) {
      case _BootState.loading:
        return const SplashScreen();
      case _BootState.failed:
        return _BootErrorScreen(
          messageKey: _bootErrorKey ?? 'boot.error.connection',
          onRetry: _boot,
        );
      case _BootState.ready:
        break;
    }

    return Consumer<AuthService>(
      builder: (context, auth, _) {
        return auth.isAuthenticated ? const AppShell() : const AuthScreen();
      },
    );
  }
}

enum _BootState { loading, ready, failed }

class _BootErrorScreen extends StatelessWidget {
  const _BootErrorScreen({required this.messageKey, required this.onRetry});

  final String messageKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo_lookup.png', width: 150),
                  const SizedBox(height: 28),
                  Icon(Icons.cloud_off_outlined, size: 42, color: c.inkMuted),
                  const SizedBox(height: 16),
                  Text(
                    context.t('boot.error.title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: c.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.t(messageKey),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.inkMuted, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.t('common.retry')),
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

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo_lookup.png', width: 150),
            const SizedBox(height: 30),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: c.brand,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.t('app.tagline'),
              style: TextStyle(color: c.inkMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
