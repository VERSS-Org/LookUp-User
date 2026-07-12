import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lookup_user/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RestoredAuthService extends AuthService {
  @override
  bool get isAuthenticated => true;

  @override
  String? get cuentaId => 'account-id';

  @override
  Map<String, dynamic>? get profile => const {
    'nombre_completo': 'Postulante de prueba',
    'rol': 'postulante',
  };

  @override
  Future<bool> tryAutoLogin() async => true;
}

class _RetryAuthService extends AuthService {
  int attempts = 0;

  @override
  Future<bool> tryAutoLogin() async {
    attempts++;
    if (attempts == 1) {
      throw ApiException('Servidor no disponible', isConnectionError: true);
    }
    return false;
  }
}

class _HangingAuthService extends AuthService {
  @override
  Future<bool> tryAutoLogin() => Completer<bool>().future;
}

class _ReadyDataService extends LookUpDataService {
  int refreshes = 0;

  @override
  Future<void> refresh(String cuentaId) async {
    refreshes++;
  }
}

class _HangingDataService extends LookUpDataService {
  @override
  Future<void> refresh(String cuentaId) => Completer<void>().future;
}

Widget _bootApp({
  required AuthService auth,
  required LookUpDataService data,
  Duration timeout = const Duration(milliseconds: 50),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeController()),
      ChangeNotifierProvider(create: (_) => LocaleController()),
      ChangeNotifierProvider<AuthService>.value(value: auth),
      ChangeNotifierProvider<LookUpDataService>.value(value: data),
    ],
    child: MaterialApp(
      theme: buildLookUpTheme(Brightness.light),
      home: SessionGate(bootTimeout: timeout),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('restored session opens the app after initial data is ready', (
    tester,
  ) async {
    final auth = _RestoredAuthService();
    final data = _ReadyDataService();

    await tester.pumpWidget(_bootApp(auth: auth, data: data));
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(data.refreshes, 1);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('transient restore failure shows retry and can reach login', (
    tester,
  ) async {
    final auth = _RetryAuthService();

    await tester.pumpWidget(_bootApp(auth: auth, data: _ReadyDataService()));
    await tester.pump();

    expect(find.text('No pudimos iniciar LookUp'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(auth.attempts, 2);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('session timeout replaces the splash with a recoverable error', (
    tester,
  ) async {
    await tester.pumpWidget(
      _bootApp(auth: _HangingAuthService(), data: _ReadyDataService()),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();

    expect(find.text('No pudimos iniciar LookUp'), findsOneWidget);
    expect(
      find.text(
        'La carga está tardando más de lo esperado. Vuelve a intentarlo.',
      ),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('secondary data never completing does not retain the splash', (
    tester,
  ) async {
    await tester.pumpWidget(
      _bootApp(auth: _RestoredAuthService(), data: _HangingDataService()),
    );
    await tester.pump();

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('No pudimos iniciar LookUp'), findsNothing);
  });
}
