import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lookup_user/main.dart';
import 'package:lookup_user/src/screens/applications_screen.dart';
import 'package:lookup_user/src/screens/company_screen.dart';
import 'package:lookup_user/src/screens/messages_screen.dart';
import 'package:lookup_user/src/screens/notifications_screen.dart';
import 'package:lookup_user/src/screens/offers_screen.dart';
import 'package:lookup_user/src/screens/profile_screen.dart';
import 'package:lookup_user/src/utils/formatters.dart';
import 'package:lookup_user/src/widgets/common.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestDataService extends LookUpDataService {
  _TestDataService({
    this.testJobs = const <Map<String, dynamic>>[],
    this.testInbox = const <Map<String, dynamic>>[],
    this.testApplications = const <Map<String, dynamic>>[],
    this.testMetrics,
    this.testAchievements = const <Map<String, dynamic>>[],
    this.testEvents = const <Map<String, dynamic>>[],
    this.testUnseenNotifications = 0,
    this.failEvents = false,
    this.failThread = false,
    this.failCompany = false,
    this.failJobDetail = false,
  });

  final List<Map<String, dynamic>> testJobs;
  final List<Map<String, dynamic>> testInbox;
  final List<Map<String, dynamic>> testApplications;
  final Map<String, dynamic>? testMetrics;
  final List<Map<String, dynamic>> testAchievements;
  final List<Map<String, dynamic>> testEvents;
  final int testUnseenNotifications;
  final bool failEvents;
  final bool failThread;
  final bool failCompany;
  final bool failJobDetail;
  int markNotificationsSeenCalls = 0;
  final List<String> markedNotificationIds = [];

  @override
  List<Map<String, dynamic>> get jobs => testJobs;

  @override
  List<Map<String, dynamic>> get inbox => testInbox;

  @override
  List<Map<String, dynamic>> get applications => testApplications;

  @override
  Map<String, dynamic>? get metrics => testMetrics;

  @override
  List<Map<String, dynamic>> get achievements => testAchievements;

  @override
  List<Map<String, dynamic>> get events => testEvents;

  @override
  int get unseenNotifications => testUnseenNotifications;

  @override
  Future<void> fetchInbox({bool notify = true}) async {}

  @override
  Future<void> fetchThread(String postulacionId, {bool notify = true}) async {
    if (failThread) throw StateError('thread failure');
  }

  @override
  Future<void> markThreadRead(String postulacionId) async {}

  @override
  Future<void> fetchEvents({bool notify = true}) async {
    if (failEvents) throw StateError('events failure');
  }

  @override
  Future<Map<String, dynamic>?> fetchCuenta(String cuentaId) async {
    if (failCompany) throw StateError('company failure');
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchJobsByCompany(
    String empresaId,
  ) async {
    if (failCompany) throw StateError('company jobs failure');
    return const [];
  }

  @override
  Future<Map<String, dynamic>?> fetchJobDetail(String puestoId) async {
    if (failJobDetail) throw StateError('job detail failure');
    return null;
  }

  @override
  Future<void> markNotificationsSeen() async {
    markNotificationsSeenCalls++;
  }

  @override
  Future<void> markNotificationSeen(Map<String, dynamic> event) async {
    markedNotificationIds.add(event['notificacion_id']?.toString() ?? '');
  }
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
  int changePasswordCalls = 0;

  @override
  Map<String, dynamic>? get profile => testProfile;

  @override
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    lastProfileUpdate = Map<String, dynamic>.from(updates);
    testProfile.addAll(updates);
    notifyListeners();
    return true;
  }

  @override
  Future<bool> changePassword(
    String passwordActual,
    String passwordNuevo,
  ) async {
    changePasswordCalls++;
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

    expect(
      find.text('Tu búsqueda laboral,\nen un solo lugar.'),
      findsOneWidget,
    );
    expect(find.text('Iniciar sesión'), findsNWidgets(2));
    expect(find.text('¿Eres una empresa?'), findsOneWidget);
    expect(find.text('Ir al portal de empresas'), findsOneWidget);
  });

  testWidgets('mobile applicant registration is one clear responsive form', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(360, 800));

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
    await tester.tap(find.text('Crear cuenta de postulante'));
    await tester.pumpAndSettle();

    expect(find.text('Crea tu cuenta de postulante'), findsOneWidget);
    expect(find.byKey(const Key('register-name-field')), findsOneWidget);
    expect(find.byKey(const Key('register-career-field')), findsOneWidget);
    expect(find.byKey(const Key('register-city-field')), findsOneWidget);
    expect(find.textContaining('Empieza a publicar'), findsNothing);
    expect(tester.widget<BrandMark>(find.byType(BrandMark)).mini, isFalse);
    expect(tester.takeException(), isNull);
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

  testWidgets('mobile redesigned sections fit realistic content at 360x800', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(360, 800));
    final data = _TestDataService(
      testJobs: const [
        {
          'puesto_id': 'job-long',
          'titulo': 'Analista de datos e inteligencia comercial junior',
          'empresa_nombre': 'Nexa Analytics y Consultoría',
          'ubicacion': 'Lima, Perú',
          'tipo_contrato': 'tiempo_completo',
          'moneda': 'PEN',
          'salario_min': 3500,
          'salario_max': 4800,
          'fecha_publicacion': '2026-07-20',
        },
      ],
      testApplications: const [
        {
          'postulacion_id': 'app-mobile-rich',
          'estado': 'entrevista',
          'fecha_postulacion': '2026-07-12',
          'puesto': {
            'titulo': 'Diseñador de experiencia de usuario e interfaces',
          },
          'empresa': {'nombre': 'Kallpa Studio Internacional'},
          'hitos': [
            {
              'tipo_evento': 'estado_actualizado',
              'estado_anterior': 'en_revision',
              'estado_nuevo': 'entrevista',
              'fecha': '2026-07-18',
            },
          ],
        },
      ],
      testInbox: const [
        {
          'postulacion_id': 'app-mobile-rich',
          'puesto_titulo': 'Diseñador UX/UI',
          'contraparte': {'nombre': 'Kallpa Studio Internacional'},
          'ultimo_mensaje': {
            'texto': 'Queremos coordinar una entrevista esta semana.',
            'fecha': '2026-07-18T10:30:00',
            'remitente_rol': 'empresa',
          },
        },
      ],
      testMetrics: const {
        'total_postulaciones': 12,
        'total_en_revision': 7,
        'total_entrevistas': 4,
        'total_exitos': 2,
        'total_rechazos': 3,
        'tasa_exito': 16.7,
      },
      testAchievements: const [
        {
          'nombre_logro': 'Primera entrevista coordinada',
          'fecha_obtencion': '2026-07-18',
        },
      ],
      testEvents: const [
        {
          'tipo_evento': 'estado_actualizado',
          'estado_nuevo': 'entrevista',
          'titulo': 'Kallpa Studio actualizó tu proceso',
          'fecha': '2026-07-18T10:30:00',
        },
      ],
      testUnseenNotifications: 1,
    );

    await tester.pumpWidget(_testShell(data: data));
    await tester.pumpAndSettle();
    expect(find.text('PROCESOS ACTIVOS'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    expect(find.text('Vacantes laborales'), findsOneWidget);
    final offersChip = tester.widget<ChoiceChip>(
      find.byKey(const Key('offers-filter-todos')),
    );
    expect(offersChip.selectedColor, const Color(0xFF2C3CA6));
    expect(offersChip.labelStyle?.color, Colors.white);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();
    expect(find.text('Mis postulaciones'), findsOneWidget);
    final applicationsChip = tester.widget<ChoiceChip>(
      find.byKey(const Key('applications-filter-todas')),
    );
    expect(applicationsChip.selectedColor, const Color(0xFF2C3CA6));
    expect(applicationsChip.labelStyle?.color, Colors.white);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(NavigationDestination).at(4));
    await tester.pumpAndSettle();
    expect(find.text('Resumen de tu proceso'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop shell exposes global search at 1440x900', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(1440, 900));
    final data = _TestDataService(testUnseenNotifications: 2);

    await tester.pumpWidget(_testShell(data: data));
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
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notifications-popover')), findsOneWidget);
    expect(find.text('Notificaciones'), findsOneWidget);
    expect(data.markNotificationsSeenCalls, 0);
    await tester.tap(find.byKey(const Key('notifications-mark-read')));
    await tester.pump();
    expect(data.markNotificationsSeenCalls, 1);
    expect(find.text('Hola, Postulante'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('slash opens global search without changing section', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(1200, 800));

    await tester.pumpWidget(_testShell());
    await tester.pumpAndSettle();
    expect(find.text('Hola, Postulante'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pumpAndSettle();

    expect(find.text('Busca en LookUp'), findsOneWidget);
    expect(find.text('Hola, Postulante'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop notification popover redirects inside the app shell', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(1200, 800));
    final data = _TestDataService(
      testEvents: const [
        {
          'notificacion_id': 'notif-shell-process',
          'tipo': 'estado_postulacion',
          'titulo': 'Tu proceso fue actualizado',
          'metadata': {'postulacion_id': 'application-shell'},
          'fecha_creacion': '2026-07-24T09:00:00',
        },
      ],
    );

    await tester.pumpWidget(_testShell(data: data));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notificaciones'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notifications-popover')), findsOneWidget);
    expect(find.text('Hola, Postulante'), findsOneWidget);

    await tester.tap(find.text('Tu proceso fue actualizado'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notifications-popover')), findsNothing);
    expect(find.text('Mis postulaciones'), findsOneWidget);
    expect(data.markedNotificationIds, ['notif-shell-process']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification page adapts to a short web viewport', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setViewport(tester, const Size(1200, 260));

    await tester.pumpWidget(_testShell());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notificaciones'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notifications-popover')), findsOneWidget);
    expect(find.text('Notificaciones'), findsOneWidget);
    expect(find.byType(Scrollable), findsWidgets);
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
      expect(find.text('Mi perfil'), findsNothing);
      expect(find.byKey(const Key('profile-change-photo')), findsOneWidget);
      expect(find.byKey(const Key('profile-edit-general')), findsOneWidget);
      expect(find.byTooltip('Editar perfil'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('   Ingeniería de software   '), findsNothing);
      expect(find.text('Ingeniería de software · Lima'), findsOneWidget);
      expect(find.text('luis@example.com · 999 888 777'), findsOneWidget);
      expect(find.textContaining('   Ingeniería'), findsNothing);

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

  testWidgets('successful password change closes its dialog', (tester) async {
    _setViewport(tester, const Size(800, 700));
    final auth = _TestAuthService(const {'nombre_completo': 'Luis Rodriguez'});

    await tester.pumpWidget(
      _testFeature(
        auth: auth,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const ChangePasswordDialog(),
                ),
                child: const Text('Abrir cambio de contraseña'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir cambio de contraseña'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(0), 'Anterior123!');
    await tester.enterText(fields.at(1), 'Nueva123!');
    await tester.enterText(fields.at(2), 'Nueva123!');
    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();

    expect(auth.changePasswordCalls, 1);
    expect(find.byType(ChangePasswordDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop messages keeps one contextual sidebar title', (
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

    expect(find.text('Mensajes'), findsOneWidget);
    expect(find.text('Aún no tienes mensajes'), findsNothing);
    expect(find.byKey(const Key('messages-list-panel')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('messages-list-panel'))).width,
      300,
    );
    expect(find.text('Buscar conversaciones'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification errors keep prior events and expose retry', (
    tester,
  ) async {
    _setViewport(tester, const Size(1200, 800));
    final data = _TestDataService(
      failEvents: true,
      testEvents: const [
        {
          'tipo_evento': 'estado_actualizado',
          'estado_nuevo': 'entrevista',
          'titulo': 'Proceso actualizado',
          'fecha': '2026-07-18T10:30:00',
        },
      ],
    );

    await tester.pumpWidget(
      _testFeature(child: const NotificationsScreen(), data: data),
    );
    await tester.pumpAndSettle();

    expect(find.text('Proceso actualizado'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('events failure'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'notification rows mark read and open safe metadata destinations',
    (tester) async {
      _setViewport(tester, const Size(720, 800));
      final data = _TestDataService(
        testEvents: const [
          {
            'notificacion_id': 'notif-job',
            'tipo': 'nueva_vacante_empresa_seguida',
            'titulo': 'Nueva vacante disponible',
            'puesto_id': 'job-7',
            'fecha_creacion': '2026-07-24T10:00:00',
          },
          {
            'notificacion_id': 'notif-process',
            'tipo': 'estado_postulacion',
            'titulo': 'Tu proceso cambió',
            'metadata': {'postulacion_id': 'application-4'},
            'fecha_creacion': '2026-07-24T09:00:00',
          },
          {
            'notificacion_id': 'notif-chat',
            'tipo': 'nuevo_mensaje',
            'titulo': 'Tienes un mensaje',
            'metadata': {'postulacion_id': 'application-8'},
            'fecha_creacion': '2026-07-24T08:00:00',
          },
          {
            'notificacion_id': 'notif-company',
            'tipo': 'empresa_recomendada',
            'titulo': 'Empresa para ti',
            'metadata': {'empresa_id': 'company-2'},
            'fecha_creacion': '2026-07-24T07:00:00',
          },
          {
            'notificacion_id': 'notif-closed-job',
            'tipo': 'vacante_guardada_cerrada',
            'titulo': 'Una vacante guardada se cerró',
            'puesto_id': 'closed-job',
            'empresa_id': 'company-closed-job',
            'fecha_creacion': '2026-07-24T06:30:00',
          },
          {
            'notificacion_id': 'notif-incomplete',
            'tipo': 'desconocida',
            'titulo': 'Aviso general',
            'metadata': {'puesto_id': ''},
            'fecha_creacion': '2026-07-24T06:00:00',
          },
        ],
      );
      String? openedJob;
      String? openedConversation;
      String? openedCompany;
      var openedProcesses = 0;

      await tester.pumpWidget(
        _testFeature(
          data: data,
          child: NotificationsScreen(
            onOpenJob: (id) => openedJob = id,
            onOpenProcesses: () => openedProcesses++,
            onOpenConversation: (id) => openedConversation = id,
            onOpenCompany: (id) => openedCompany = id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nueva vacante disponible'));
      await tester.pump();
      expect(openedJob, 'job-7');

      await tester.tap(find.text('Tu proceso cambió'));
      await tester.pump();
      expect(openedProcesses, 1);

      await tester.tap(find.text('Tienes un mensaje'));
      await tester.pump();
      expect(openedConversation, 'application-8');

      await tester.tap(find.text('Empresa para ti'));
      await tester.pump();
      expect(openedCompany, 'company-2');

      await tester.tap(find.text('Una vacante guardada se cerró'));
      await tester.pump();
      expect(openedCompany, 'company-closed-job');
      expect(openedJob, 'job-7');

      await tester.tap(find.text('Aviso general'));
      await tester.pump();
      expect(data.markedNotificationIds, [
        'notif-job',
        'notif-process',
        'notif-chat',
        'notif-company',
        'notif-closed-job',
        'notif-incomplete',
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('detail loaders expose recoverable errors', (tester) async {
    _setViewport(tester, const Size(1200, 800));
    final data = _TestDataService(failCompany: true, failJobDetail: true);

    await tester.pumpWidget(
      _testFeature(
        child: const CompanyScreen(empresaId: 'company-error'),
        data: data,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('company failure'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _testFeature(
        child: const OfferDetailPage(
          job: {
            'puesto_id': 'job-error',
            'titulo': 'Vacante con detalle temporalmente no disponible',
            'estado': 'abierto',
          },
        ),
        data: data,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('job detail failure'), findsOneWidget);
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

  testWidgets('chat thread errors expose retry without losing the inbox', (
    tester,
  ) async {
    _setViewport(tester, const Size(1200, 800));
    final data = _TestDataService(
      failThread: true,
      testInbox: const [
        {
          'postulacion_id': 'app-thread-error',
          'puesto_titulo': 'Frontend',
          'contraparte': {'nombre': 'Empresa disponible'},
          'ultimo_mensaje': {'texto': 'Seguimos en contacto'},
        },
      ],
    );

    await tester.pumpWidget(
      _testFeature(child: const MessagesScreen(embedded: true), data: data),
    );
    await tester.pumpAndSettle();

    expect(find.text('Empresa disponible'), findsWidgets);
    expect(find.textContaining('thread failure'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
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
          'empresa': {
            'nombre': 'Empresa Exacta',
            'foto_url': 'https://example.test/empresa-exacta.png',
          },
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
    final companyLogo = tester.widget<CompanyAvatar>(
      find.byKey(const Key('application-company-logo-app-exact')),
    );
    expect(companyLogo.fotoUrl, 'https://example.test/empresa-exacta.png');
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
    expect(find.text('Mensajes'), findsOneWidget);

    await tester.tap(find.text('Empresa Móvil'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mobile-chat-screen')), findsOneWidget);
    expect(find.byKey(const Key('selected-thread-app-mobile')), findsOneWidget);
    expect(find.byKey(const Key('chat-message-field')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('theme uses Manrope, Sora headings and uniform page transitions', () {
    final theme = buildLookUpTheme(Brightness.light);

    expect(theme.textTheme.bodyMedium?.fontFamily, kLookUpFontFamily);
    expect(theme.textTheme.headlineSmall?.fontFamily, kLookUpHeadingFontFamily);
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
