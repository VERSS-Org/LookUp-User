import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lookup_user/main.dart';
import 'package:lookup_user/src/screens/applications_screen.dart';
import 'package:lookup_user/src/screens/messages_screen.dart';
import 'package:lookup_user/src/screens/profile_screen.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestDataService extends LookUpDataService {
  _TestDataService({
    this.testInbox = const <Map<String, dynamic>>[],
    this.testApplications = const <Map<String, dynamic>>[],
  });

  final List<Map<String, dynamic>> testInbox;
  final List<Map<String, dynamic>> testApplications;

  @override
  List<Map<String, dynamic>> get inbox => testInbox;

  @override
  List<Map<String, dynamic>> get applications => testApplications;

  @override
  Future<void> fetchInbox({bool notify = true}) async {}

  @override
  Future<void> fetchThread(String postulacionId, {bool notify = true}) async {}

  @override
  Future<void> markThreadRead(String postulacionId) async {}

  @override
  Future<void> fetchEvents({bool notify = true}) async {}

  @override
  Future<void> markNotificationsSeen() async {}
}

class _TestAuthService extends AuthService {
  _TestAuthService(Map<String, dynamic> profile)
    : testProfile = Map<String, dynamic>.from(profile) {
    final perfil = testProfile['perfil'];
    if (perfil is Map) {
      testProfile['perfil'] = Map<String, dynamic>.from(perfil);
    }
  }

  final Map<String, dynamic> testProfile;
  Map<String, dynamic>? lastProfileUpdate;

  @override
  Map<String, dynamic>? get profile => testProfile;

  @override
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    lastProfileUpdate = Map<String, dynamic>.from(updates);
    testProfile.addAll(updates);
    notifyListeners();
    return true;
  }
}

Widget _testShell({LookUpDataService? data, AuthService? auth}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeController()),
      ChangeNotifierProvider(create: (_) => LocaleController()),
      ChangeNotifierProvider<AuthService>(create: (_) => auth ?? AuthService()),
      ChangeNotifierProvider<LookUpDataService>(
        create: (_) => data ?? _TestDataService(),
      ),
    ],
    child: MaterialApp(
      theme: buildLookUpTheme(Brightness.light),
      home: const AppShell(),
    ),
  );
}

Widget _testFeature({
  required Widget child,
  Map<String, dynamic>? profile,
  AuthService? auth,
  LookUpDataService? data,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeController()),
      ChangeNotifierProvider(create: (_) => LocaleController()),
      ChangeNotifierProvider<AuthService>(
        create: (_) =>
            auth ?? _TestAuthService(profile ?? const <String, dynamic>{}),
      ),
      ChangeNotifierProvider<LookUpDataService>(
        create: (_) => data ?? _TestDataService(),
      ),
    ],
    child: MaterialApp(theme: buildLookUpTheme(Brightness.light), home: child),
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
          ChangeNotifierProvider<LookUpDataService>(
            create: (_) => _TestDataService(),
          ),
        ],
        child: const LookUpUserApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Encuentra tu siguiente oportunidad'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('¿Eres una empresa?'), findsOneWidget);
    expect(find.text('Ir al portal de empresas'), findsOneWidget);
  });

  testWidgets('mobile shell keeps actions ordered at 360x800', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(360, 800));

    await tester.pumpWidget(_testShell());
    await tester.pumpAndSettle();

    expect(find.text('Hola, Postulante'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.byKey(const Key('mobile-bottom-navigation')), findsOneWidget);
    expect(find.text('Accesos rápidos'), findsNothing);
    expect(find.byType(SearchBar), findsNothing);

    final brand = tester.widget<BrandMark>(find.byType(BrandMark));
    expect(brand.mini, isFalse);

    final chatX = tester.getCenter(find.byTooltip('Mensajes')).dx;
    final logoX = tester.getCenter(find.byType(BrandMark)).dx;
    final notificationX = tester.getCenter(find.byTooltip('Notificaciones')).dx;
    final profileX = tester.getCenter(find.byType(InitialsAvatar)).dx;

    expect(chatX, lessThan(logoX));
    expect(logoX, lessThan(notificationX));
    expect(notificationX, lessThan(profileX));

    await tester.tap(find.byKey(const Key('mobile-search-destination')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mobile-search-field')), findsOneWidget);
    expect(find.byKey(const Key('mobile-bottom-navigation')), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.byTooltip('Notificaciones'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notifications-popover')), findsNothing);
    expect(find.text('Notificaciones'), findsOneWidget);
    expect(find.byTooltip('Volver'), findsOneWidget);
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
    expect(
      tester.getSize(find.byType(SearchBar)).width,
      greaterThanOrEqualTo(470),
    );
    expect(find.text('LookUp'), findsNothing);
    expect(find.text('Progreso'), findsOneWidget);
    expect(find.text('Métricas'), findsNothing);

    final messageX = tester.getCenter(find.byTooltip('Mensajes')).dx;
    final notificationX = tester.getCenter(find.byTooltip('Notificaciones')).dx;
    final profileX = tester.getCenter(find.byType(InitialsAvatar)).dx;
    expect(messageX, lessThan(notificationX));
    expect(notificationX, lessThan(profileX));

    await tester.tap(find.byTooltip('Notificaciones'));
    await tester.pump();
    final popover = find.byKey(const Key('notifications-popover'));
    expect(popover, findsOneWidget);
    expect(tester.getSize(popover).width, lessThan(500));
    expect(tester.getSize(popover).height, lessThan(600));
    expect(find.text('Hola, Postulante'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile search becomes vacancies cleanly after desktop resize', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(360, 800));

    await tester.pumpWidget(_testShell());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mobile-search-destination')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mobile-search-field')), findsOneWidget);
    expect(find.byKey(const Key('mobile-bottom-navigation')), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mobile-search-field')), findsNothing);
    expect(find.byKey(const Key('mobile-bottom-navigation')), findsNothing);
    expect(find.byType(SearchBar), findsOneWidget);
    expect(find.text('Vacantes laborales'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop navbar search stays wide without overflowing at 1024', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(1024, 768));

    await tester.pumpWidget(_testShell());
    await tester.pumpAndSettle();

    expect(find.byType(SearchBar), findsOneWidget);
    expect(tester.getSize(find.byType(SearchBar)).width, 280);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(960, 768);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(SearchBar)).width,
      greaterThanOrEqualTo(200),
    );
    expect(
      tester.getSize(find.byType(SearchBar)).width,
      lessThanOrEqualTo(280),
    );
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1180, 768);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(SearchBar)).width, 380);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1600, 900);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(SearchBar)).width, 540);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'desktop profile aligns personal values and removes duplicate header',
    (tester) async {
      _setViewport(tester, const Size(1200, 900));

      await tester.pumpWidget(
        _testFeature(
          child: const ProfileScreen(embedded: true),
          profile: const {
            'nombre_completo': 'Luis Rodriguez',
            'email': 'luis@example.com',
            'carrera': '   Ingeniería de software   ',
            'telefono': ' 999 888 777 ',
            'ciudad': ' Lima ',
            'perfil': <String, dynamic>{},
          },
        ),
      );
      await tester.pumpAndSettle();

      final pageScroll = find.byKey(const Key('profile-page-scroll'));
      expect(pageScroll, findsOneWidget);
      expect(tester.getSize(pageScroll).width, 1200);
      expect(
        find.ancestor(of: pageScroll, matching: find.byType(PageContainer)),
        findsNothing,
      );
      expect(find.text('Mi perfil'), findsNothing);
      expect(find.byKey(const Key('profile-change-photo')), findsOneWidget);
      expect(find.byKey(const Key('profile-edit-general')), findsOneWidget);
      expect(find.byTooltip('Editar perfil'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('   Ingeniería de software   '), findsNothing);
      expect(find.text('Ingeniería de software'), findsOneWidget);
      expect(find.text('999 888 777'), findsOneWidget);
      expect(find.text('Lima'), findsOneWidget);

      final careerX = tester.getTopLeft(find.text('Ingeniería de software')).dx;
      final phoneX = tester.getTopLeft(find.text('999 888 777')).dx;
      final cityX = tester.getTopLeft(find.text('Lima')).dx;
      final careerLabelRight = tester
          .getTopRight(find.text('Carrera o especialidad'))
          .dx;
      expect((careerX - phoneX).abs(), lessThan(1));
      expect((careerX - cityX).abs(), lessThan(1));
      expect(careerX - careerLabelRight, lessThan(100));

      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Sobre mí'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile-edit-general')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Editar perfil'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mobile profile keeps edit actions beside the photo action', (
    tester,
  ) async {
    _setViewport(tester, const Size(360, 800));

    await tester.pumpWidget(_testFeature(child: const ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.byKey(const Key('profile-change-photo')), findsOneWidget);
    expect(find.byKey(const Key('profile-edit-general')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile privacy toggle persists mostrar_email', (tester) async {
    _setViewport(tester, const Size(1200, 900));
    final auth = _TestAuthService(const {
      'nombre_completo': 'Luis Rodriguez',
      'email': 'luis@example.com',
      'perfil': <String, dynamic>{'mostrar_email': true},
    });

    await tester.pumpWidget(
      _testFeature(child: const ProfileScreen(embedded: true), auth: auth),
    );
    await tester.pumpAndSettle();

    final toggle = find.byKey(const Key('profile-show-email-switch'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    final perfil = auth.lastProfileUpdate?['perfil'] as Map<String, dynamic>?;
    expect(perfil?['mostrar_email'], isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop messages omits the redundant inner title', (
    tester,
  ) async {
    _setViewport(tester, const Size(1200, 800));
    final data = _TestDataService(
      testInbox: const [
        {
          'postulacion_id': 'app-1',
          'puesto_titulo': 'Desarrollador Flutter',
          'contraparte': {'nombre': 'CocaCola'},
          'ultimo_mensaje': {
            'texto': 'Hola Luis',
            'fecha': '2026-07-13T10:30:00',
            'remitente_rol': 'empresa',
          },
          'no_leidos': 1,
        },
      ],
    );

    await tester.pumpWidget(
      _testFeature(child: const MessagesScreen(embedded: true), data: data),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mensajes'), findsNothing);
    expect(find.text('Aún no tienes mensajes'), findsNothing);
    expect(find.byKey(const Key('messages-list-panel')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('messages-list-panel'))).width,
      360,
    );
    expect(find.text('Buscar conversaciones'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('messages selects the requested async inbox thread', (
    tester,
  ) async {
    _setViewport(tester, const Size(1200, 800));
    final data = _TestDataService(
      testInbox: const [
        {
          'postulacion_id': 'app-1',
          'puesto_titulo': 'Frontend',
          'contraparte': {'nombre': 'Empresa A'},
          'ultimo_mensaje': {'texto': 'Uno'},
        },
        {
          'postulacion_id': 'app-2',
          'puesto_titulo': 'Backend',
          'contraparte': {'nombre': 'Empresa B'},
          'ultimo_mensaje': {'texto': 'Dos'},
        },
      ],
    );

    await tester.pumpWidget(
      _testFeature(
        child: const MessagesScreen(
          embedded: true,
          initialPostulacionId: 'app-2',
        ),
        data: data,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('selected-thread-app-2')), findsOneWidget);
    expect(find.byKey(const Key('messages-empty-pane')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('process open conversation targets its application thread', (
    tester,
  ) async {
    _setViewport(tester, const Size(1200, 800));
    String? openedId;
    final data = _TestDataService(
      testApplications: const [
        {
          'postulacion_id': 'app-exact',
          'estado': 'entrevista',
          'fecha_postulacion': '2026-07-12',
          'puesto': {'titulo': 'Backend'},
          'empresa': {'nombre': 'Empresa Exacta'},
          'hitos': <Map<String, dynamic>>[],
        },
      ],
      testInbox: const [
        {
          'postulacion_id': 'app-exact',
          'puesto_titulo': 'Backend',
          'contraparte': {'nombre': 'Empresa Exacta'},
        },
      ],
    );

    await tester.pumpWidget(
      _testFeature(
        child: ApplicationsScreen(onOpenConversation: (id) => openedId = id),
        data: data,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('application-open-chat-app-exact')));
    await tester.pump();

    expect(openedId, 'app-exact');
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop process switches shell to the exact message thread', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(1200, 800));
    final data = _TestDataService(
      testApplications: const [
        {
          'postulacion_id': 'app-shell',
          'estado': 'entrevista',
          'fecha_postulacion': '2026-07-12',
          'puesto': {'titulo': 'QA'},
          'empresa': {'nombre': 'Empresa Shell'},
          'hitos': <Map<String, dynamic>>[],
        },
      ],
      testInbox: const [
        {
          'postulacion_id': 'app-shell',
          'puesto_titulo': 'QA',
          'contraparte': {'nombre': 'Empresa Shell'},
          'ultimo_mensaje': {'texto': 'Coordinemos'},
        },
      ],
    );

    await tester.pumpWidget(_testShell(data: data));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Procesos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('application-open-chat-app-shell')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('selected-thread-app-shell')), findsOneWidget);
    expect(find.text('Mis postulaciones'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile messages opens a compact chat in the same flow', (
    tester,
  ) async {
    _setViewport(tester, const Size(360, 800));
    final data = _TestDataService(
      testInbox: const [
        {
          'postulacion_id': 'app-mobile',
          'puesto_titulo': 'Frontend',
          'estado_postulacion': 'entrevista',
          'contraparte': {'nombre': 'Empresa Móvil'},
          'ultimo_mensaje': {'texto': 'Hola'},
        },
      ],
    );

    await tester.pumpWidget(
      _testFeature(child: const MessagesScreen(), data: data),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mobile-messages-list')), findsOneWidget);
    expect(find.text('Mensajes'), findsNothing);

    await tester.tap(find.text('Empresa Móvil'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mobile-chat-screen')), findsOneWidget);
    expect(find.byKey(const Key('selected-thread-app-mobile')), findsOneWidget);
    expect(find.byKey(const Key('chat-message-field')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('theme uses Helvetica fallbacks and uniform page transitions', () {
    final theme = buildLookUpTheme(Brightness.light);

    expect(theme.textTheme.bodyMedium?.fontFamily, kLookUpFontFamily);
    expect(theme.textTheme.bodyMedium?.fontFamilyFallback, contains('Arial'));
    expect(
      theme.pageTransitionsTheme.builders.values,
      everyElement(isA<LookUpPageTransitionsBuilder>()),
    );
  });

  testWidgets('structured process events never expose technical states', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LocaleController(),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Column(
              children: [
                Text(
                  eventDescriptionT(context, const {
                    'tipo_evento': 'estado_actualizado',
                    'estado_anterior': 'pendiente',
                    'estado_nuevo': 'en_revision',
                    'descripcion':
                        'Estado actualizado de pendiente a en_revision',
                  }),
                ),
                Text(
                  prettyEventText(
                    context,
                    'Estado actualizado de entrevista a rechazado',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      find.text('Estado actualizado de Pendiente a En revisión'),
      findsOneWidget,
    );
    expect(
      find.text('Estado actualizado de entrevista a rechazado'),
      findsOneWidget,
    );
    expect(find.textContaining('rechazadoado'), findsNothing);
    expect(find.textContaining('en_revision'), findsNothing);
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
