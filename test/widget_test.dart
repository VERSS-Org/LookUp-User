import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lookup_user/main.dart';
import 'package:lookup_user/src/widgets/common.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _testShell() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeController()),
      ChangeNotifierProvider(create: (_) => LocaleController()),
      ChangeNotifierProvider(create: (_) => AuthService()),
      ChangeNotifierProvider(create: (_) => LookUpDataService()),
    ],
    child: MaterialApp(
      theme: buildLookUpTheme(Brightness.light),
      home: const AppShell(),
    ),
  );
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('shows the auth screen when there is no saved session', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => LocaleController()),
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => LookUpDataService()),
        ],
        child: const LookUpUserApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Encuentra tu siguiente oportunidad'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('mobile shell keeps actions ordered at 360x800', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(360, 800));

    await tester.pumpWidget(_testShell());
    await tester.pumpAndSettle();

    expect(find.text('Hola, Postulante'), findsOneWidget);
    expect(find.text('Vacantes'), findsWidgets);
    expect(find.text('Procesos'), findsWidgets);
    expect(find.text('Métricas'), findsWidgets);
    expect(find.byType(SearchBar), findsNothing);

    final brand = tester.widget<BrandMark>(find.byType(BrandMark));
    expect(brand.mini, isFalse);

    final chatX = tester.getCenter(find.byTooltip('Mensajes')).dx;
    final logoX = tester.getCenter(find.byType(BrandMark)).dx;
    final searchX = tester
        .getCenter(find.byTooltip('Buscar vacantes o empresas'))
        .dx;
    final notificationX = tester.getCenter(find.byTooltip('Notificaciones')).dx;
    final profileX = tester.getCenter(find.byType(InitialsAvatar)).dx;

    expect(chatX, lessThan(logoX));
    expect(searchX, lessThan(notificationX));
    expect(notificationX, lessThan(profileX));
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop shell exposes global search at 1440x900', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(1440, 900));

    await tester.pumpWidget(_testShell());
    await tester.pumpAndSettle();

    expect(find.byType(SearchBar), findsOneWidget);
    expect(find.text('Buscar vacantes o empresas'), findsOneWidget);
    expect(find.text('LookUp'), findsNothing);

    final messageX = tester.getCenter(find.byTooltip('Mensajes')).dx;
    final notificationX = tester.getCenter(find.byTooltip('Notificaciones')).dx;
    final profileX = tester.getCenter(find.byType(InitialsAvatar)).dx;
    expect(messageX, lessThan(notificationX));
    expect(notificationX, lessThan(profileX));
    expect(tester.takeException(), isNull);
  });

  test(
    'stored session without refresh token is rejected and cleared',
    () async {
      SharedPreferences.setMockInitialValues({
        'token': 'access-token',
        'cuentaId': 'account-id',
        'role': 'postulante',
      });
      final auth = AuthService();

      expect(await auth.tryAutoLogin(), isFalse);
      expect(auth.isAuthenticated, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), isNull);
      expect(prefs.getString('cuentaId'), isNull);
      expect(prefs.getString('role'), isNull);
    },
  );
}
