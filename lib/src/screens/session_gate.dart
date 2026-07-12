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
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  bool _isBooting = true;
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
    final auth = context.read<AuthService>();
    await auth.tryAutoLogin();
    if (!mounted) return;

    final cuentaId = auth.cuentaId;
    if (cuentaId != null) {
      await context.read<LookUpDataService>().refresh(cuentaId);
    }

    if (mounted) {
      setState(() => _isBooting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isBooting) {
      return const SplashScreen();
    }

    return Consumer<AuthService>(
      builder: (context, auth, _) {
        return auth.isAuthenticated ? const AppShell() : const AuthScreen();
      },
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
