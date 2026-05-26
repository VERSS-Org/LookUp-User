import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kBrandBlue = Color(0xFF28348A);
const Color kBrandBlueAlt = Color(0xFF3A4BC4);
const Color kSkyBlue = Color(0xFF22A9E8);
const Color kInk = Color(0xFF172033);
const Color kInkMuted = Color(0xFF6B7591);
const Color kSurface = Color(0xFFEFF2F9);
const Color kHairline = Color(0xFFE6EBF4);
const Color kFieldFill = Color(0xFFF3F5FB);

/// Degradado de marca usado en cabeceras y acentos destacados.
const LinearGradient kBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kBrandBlue, Color(0xFF2F4FBE), kSkyBlue],
);

/// Sombra suave y aireada para tarjetas y superficies elevadas.
List<BoxShadow> softShadow({
  double opacity = 0.08,
  double blur = 24,
  double y = 12,
}) {
  return [
    BoxShadow(
      color: kBrandBlue.withValues(alpha: opacity),
      blurRadius: blur,
      offset: Offset(0, y),
    ),
  ];
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LookUpDataService()),
      ],
      child: const LookUpUserApp(),
    ),
  );
}

class LookUpUserApp extends StatelessWidget {
  const LookUpUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LookUp',
      theme: _buildLookUpTheme(),
      home: const SessionGate(),
    );
  }
}

ThemeData _buildLookUpTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kBrandBlue,
      primary: kBrandBlue,
      secondary: kSkyBlue,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: kSurface,
  );

  final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
      .apply(bodyColor: kInk, displayColor: kInk)
      .copyWith(
        titleLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: kInk,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(height: 1.35, color: kInk),
      );

  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: kInk,
      surfaceTintColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: kInk,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 8,
      shadowColor: kBrandBlue.withValues(alpha: 0.10),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        elevation: 2,
        shadowColor: kBrandBlue.withValues(alpha: 0.45),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kBrandBlue,
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(color: kBrandBlue.withValues(alpha: 0.35), width: 1.4),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kBrandBlue,
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kFieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.plusJakartaSans(color: kInkMuted),
      labelStyle: GoogleFonts.plusJakartaSans(color: kInkMuted),
      floatingLabelStyle: GoogleFonts.plusJakartaSans(
        color: kBrandBlue,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: kInkMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kHairline, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kBrandBlue, width: 1.6),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: kHairline,
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 3,
      shadowColor: kBrandBlue.withValues(alpha: 0.18),
      indicatorColor: kBrandBlue.withValues(alpha: 0.12),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? kBrandBlue : kInkMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? kBrandBlue : kInkMuted,
          size: 24,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kInk,
      contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: kInk,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kBrandBlue),
    listTileTheme: const ListTileThemeData(iconColor: kBrandBlue),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: kInk,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12),
    ),
  );
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized =>
      statusCode == 401 || message.toLowerCase().contains('token');

  @override
  String toString() => message;
}

class ApiService {
  static const String _defaultBaseUrl = String.fromEnvironment(
    'LOOKUP_API_BASE_URL',
    defaultValue:
        'https://backend-ufl2-git-main-glitter22s-projects.vercel.app/api/',
  );
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  final Uri _baseUri = Uri.parse(_normalizeBaseUrl(_defaultBaseUrl));
  String? _token;
  Future<bool> Function()? _refreshTokenHandler;

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final apiBase = trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
    return '$apiBase/';
  }

  void setToken(String? token) {
    _token = token;
  }

  void setRefreshTokenHandler(Future<bool> Function()? handler) {
    _refreshTokenHandler = handler;
  }

  Future<Map<String, String>> _headers() async {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      _baseUri.resolve(endpoint),
      headers: await _headers(),
    );
    return _processResponse(
      await _retryIfUnauthorized(
        response,
        () async =>
            http.get(_baseUri.resolve(endpoint), headers: await _headers()),
      ),
    );
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool retryOnUnauthorized = true,
  }) async {
    var response = await http.post(
      _baseUri.resolve(endpoint),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 307 || response.statusCode == 308) {
      final location = response.headers['location'];
      if (location != null) {
        response = await http.post(
          Uri.parse(location),
          headers: await _headers(),
          body: jsonEncode(body),
        );
      }
    }

    if (!retryOnUnauthorized) return _processResponse(response);

    return _processResponse(
      await _retryIfUnauthorized(response, () async {
        var retry = await http.post(
          _baseUri.resolve(endpoint),
          headers: await _headers(),
          body: jsonEncode(body),
        );

        if (retry.statusCode == 307 || retry.statusCode == 308) {
          final location = retry.headers['location'];
          if (location != null) {
            retry = await http.post(
              Uri.parse(location),
              headers: await _headers(),
              body: jsonEncode(body),
            );
          }
        }
        return retry;
      }),
    );
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final response = await http.patch(
      _baseUri.resolve(endpoint),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _processResponse(
      await _retryIfUnauthorized(
        response,
        () async => http.patch(
          _baseUri.resolve(endpoint),
          headers: await _headers(),
          body: jsonEncode(body),
        ),
      ),
    );
  }

  Future<dynamic> uploadFile(
    String endpoint,
    String fieldName,
    XFile file,
  ) async {
    Future<http.Response> send() async {
      final request = http.MultipartRequest('POST', _baseUri.resolve(endpoint));
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          await file.readAsBytes(),
          filename: file.name,
        ),
      );
      return http.Response.fromStream(await request.send());
    }

    final response = await send();
    return _processResponse(await _retryIfUnauthorized(response, send));
  }

  Future<http.Response> _retryIfUnauthorized(
    http.Response response,
    Future<http.Response> Function() retry,
  ) async {
    if (response.statusCode != 401 || _refreshTokenHandler == null) {
      return response;
    }
    final refreshed = await _refreshTokenHandler!();
    return refreshed ? retry() : response;
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    final detail = decoded is Map ? decoded['detail'] : null;
    throw ApiException(
      detail?.toString() ?? 'Error ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }
}

class AuthService with ChangeNotifier {
  final ApiService _api = ApiService();

  String? _token;
  String? _refreshToken;
  String? _cuentaId;
  String? _role;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;

  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get cuentaId => _cuentaId;
  String? get role => _role;
  Map<String, dynamic>? get profile => _profile;

  AuthService() {
    _api.setRefreshTokenHandler(refreshAccessToken);
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');
    final savedCuentaId = prefs.getString('cuentaId');

    if (savedToken == null || savedCuentaId == null) {
      return false;
    }

    _token = savedToken;
    _refreshToken = prefs.getString('refreshToken');
    _cuentaId = savedCuentaId;
    _role = prefs.getString('role') ?? 'postulante';
    _api.setToken(_token);

    try {
      await fetchProfile();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Stored session is not valid: $e');
    }

    try {
      if (await refreshAccessToken()) {
        await fetchProfile();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Stored session refresh failed: $e');
    }

    await logout();
    return false;
  }

  Future<bool> login(String email, String password) async {
    return _withLoading(() async {
      final response = _asMap(
        await _api.post('iam/login', {
          'email': email.trim(),
          'password': password,
        }),
      );

      if (response['rol'] != 'postulante') {
        throw ApiException('Esta app es solo para postulantes.');
      }

      await _saveSession(response);
      await fetchProfile();
      return true;
    });
  }

  Future<bool> register({
    required String nombreCompleto,
    required String email,
    required String password,
    String? carrera,
    String? telefono,
    String? ciudad,
  }) async {
    return _withLoading(() async {
      await _api.post('iam/registrar', {
        'nombre_completo': nombreCompleto.trim(),
        'email': email.trim(),
        'password': password,
        'rol': 'postulante',
        'carrera': carrera?.trim().isEmpty == true ? null : carrera?.trim(),
        'telefono': telefono?.trim().isEmpty == true ? null : telefono?.trim(),
        'ciudad': ciudad?.trim().isEmpty == true ? null : ciudad?.trim(),
      });
      return login(email, password);
    });
  }

  Future<void> fetchProfile() async {
    if (_cuentaId == null) return;
    _profile = _asMap(await _api.get('iam/cuenta/$_cuentaId'));
    notifyListeners();
  }

  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = _asMap(
        await _api.post('iam/refresh-token', {
          'refresh_token': _refreshToken,
        }, retryOnUnauthorized: false),
      );
      final newToken = response['access_token']?.toString();
      if (newToken == null || newToken.isEmpty) return false;

      _token = newToken;
      _api.setToken(newToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', newToken);
      return true;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (_cuentaId == null) return false;

    return _withLoading(() async {
      _profile = _asMap(await _api.patch('iam/cuenta/$_cuentaId', updates));
      notifyListeners();
      return true;
    });
  }

  Future<bool> uploadProfilePhoto(XFile file) async {
    if (_cuentaId == null) return false;

    return _withLoading(() async {
      _profile = _asMap(
        await _api.uploadFile('iam/cuenta/$_cuentaId/foto', 'file', file),
      );
      notifyListeners();
      return true;
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _token = null;
    _refreshToken = null;
    _cuentaId = null;
    _role = null;
    _profile = null;
    _api.setToken(null);
    notifyListeners();
  }

  Future<void> _saveSession(Map<String, dynamic> response) async {
    _token = response['access_token']?.toString();
    _refreshToken = response['refresh_token']?.toString();
    _cuentaId = response['cuenta_id']?.toString();
    _role = response['rol']?.toString() ?? 'postulante';

    if (_token == null || _cuentaId == null) {
      throw ApiException('Respuesta de login incompleta.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('cuentaId', _cuentaId!);
    await prefs.setString('role', _role!);
    if (_refreshToken != null) {
      await prefs.setString('refreshToken', _refreshToken!);
    }
    _api.setToken(_token);
  }

  Future<T> _withLoading<T>(Future<T> Function() action) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class LookUpDataService with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _applications = [];
  final Map<String, List<Map<String, dynamic>>> _contactsByApplication = {};
  Map<String, dynamic>? _metrics;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get jobs => _jobs;
  List<Map<String, dynamic>> get applications => _applications;
  Map<String, dynamic>? get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> contactsFor(String postulacionId) {
    return _contactsByApplication[postulacionId] ??
        const <Map<String, dynamic>>[];
  }

  void clear() {
    _jobs = [];
    _applications = [];
    _contactsByApplication.clear();
    _metrics = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh(String cuentaId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final errors = <String>[];
    try {
      await fetchJobs(notify: false);
    } catch (e) {
      errors.add(e.toString());
    }

    try {
      await fetchApplications(cuentaId, notify: false);
    } catch (e) {
      errors.add(e.toString());
    }

    try {
      await fetchMetrics(cuentaId, notify: false);
    } catch (e) {
      errors.add(e.toString());
    } finally {
      if (errors.isNotEmpty) {
        _error = errors.first;
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchJobs({bool notify = true}) async {
    final response = await _api.get('puesto/?estado=abierto');
    _jobs = _asMapList(response);
    if (notify) notifyListeners();
  }

  Future<void> fetchApplications(String cuentaId, {bool notify = true}) async {
    final response = await _api.get('postulacion/?candidato_id=$cuentaId');
    _applications = _asMapList(response);
    await _fetchContactsForApplications();
    if (notify) notifyListeners();
  }

  Future<void> fetchMetrics(String cuentaId, {bool notify = true}) async {
    _metrics = _asMap(await _api.get('metricas/resumen/$cuentaId'));
    if (notify) notifyListeners();
  }

  Future<void> applyToJob(String cuentaId, String puestoId) async {
    await _api.post('postulacion/', {
      'candidato_id': cuentaId,
      'puesto_id': puestoId,
      'documentos_adjuntos': <Map<String, dynamic>>[],
    });
    await refresh(cuentaId);
  }

  Future<void> sendContactMessage(
    String cuentaId,
    String postulacionId,
    String message,
  ) async {
    await _api.post('contacto/mensaje', {
      'postulacion_id': postulacionId,
      'mensaje_texto': message,
    });
    await fetchApplications(cuentaId);
  }

  bool hasAppliedTo(String puestoId) {
    return _applications.any((application) {
      final puesto = _asMap(application['puesto']);
      return puesto['puesto_id']?.toString() == puestoId;
    });
  }

  Future<void> _fetchContactsForApplications() async {
    _contactsByApplication.clear();
    for (final application in _applications) {
      final postulacionId = application['postulacion_id']?.toString();
      if (postulacionId == null || postulacionId.isEmpty) continue;
      try {
        final response = await _api.get(
          'contacto/?postulacion_id=$postulacionId',
        );
        _contactsByApplication[postulacionId] = _asMapList(response);
      } catch (_) {
        _contactsByApplication[postulacionId] = <Map<String, dynamic>>[];
      }
    }
  }

  List<Map<String, dynamic>> latestEvents() {
    final events = <Map<String, dynamic>>[];
    for (final application in _applications) {
      final puesto = _asMap(application['puesto']);
      final postulacionId = application['postulacion_id']?.toString() ?? '';
      for (final hito in _asMapList(application['hitos'])) {
        events.add({
          'title': puesto['titulo'] ?? 'Postulacion',
          'description':
              hito['descripcion'] ?? application['estado'] ?? 'Actualizacion',
          'date': hito['fecha'],
        });
      }
      for (final contacto in contactsFor(postulacionId)) {
        final feedback = _asMap(contacto['ultimo_feedback']);
        events.add({
          'title': puesto['titulo'] ?? 'Feedback',
          'description': feedback['mensaje'] ?? 'La empresa envio feedback.',
          'date': contacto['fecha_hora'],
        });
      }
    }
    events.sort(
      (a, b) =>
          (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString()),
    );
    return events.take(5).toList();
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  bool _isBooting = true;

  @override
  void initState() {
    super.initState();
    _boot();
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kBrandGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Image.asset('assets/images/logo_lookup.png', width: 148),
              ),
              const SizedBox(height: 34),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Tu busqueda laboral, en un solo lugar',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final formWidth = viewportWidth < 700
        ? (viewportWidth - 128).clamp(280, 320).toDouble()
        : 440.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE7EEFB), kSurface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: formWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        margin: const EdgeInsets.only(bottom: 22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: softShadow(opacity: 0.12, blur: 26, y: 12),
                        ),
                        child: Image.asset(
                          'assets/images/logo_lookup.png',
                          height: 64,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: softShadow(opacity: 0.10, blur: 30, y: 16),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isRegistering
                                  ? 'Crea tu cuenta de postulante'
                                  : 'Encuentra tu siguiente oportunidad',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                color: kInk,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isRegistering
                                  ? 'Completa tus datos para empezar a postular.'
                                  : 'Inicia sesion para revisar ofertas y tu avance.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: kInkMuted,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 26),
                            if (_isRegistering) ...[
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre completo',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) =>
                                    _required(value, 'Ingresa tu nombre.'),
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Correo electronico',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || !value.contains('@')) {
                                  return 'Ingresa un correo valido.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _hidePassword,
                              decoration: InputDecoration(
                                labelText: 'Contrasena',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _hidePassword = !_hidePassword,
                                  ),
                                  icon: Icon(
                                    _hidePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.length < 8) {
                                  return 'Debe tener al menos 8 caracteres.';
                                }
                                return null;
                              },
                            ),
                            if (_isRegistering) ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _careerController,
                                decoration: const InputDecoration(
                                  labelText: 'Carrera o especialidad',
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Telefono',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  labelText: 'Ciudad',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            if (_error != null) ErrorBanner(message: _error!),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: auth.isLoading ? null : _submit,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isRegistering
                                          ? 'Crear cuenta'
                                          : 'Iniciar sesion',
                                    ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : () => setState(() {
                                      _isRegistering = !_isRegistering;
                                      _error = null;
                                    }),
                              child: Text(
                                _isRegistering
                                    ? 'Ya tengo una cuenta'
                                    : 'Crear cuenta de postulante',
                              ),
                            ),
                          ],
                        ),
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

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenTab: (index) => setState(() => _index = index)),
      const OffersScreen(),
      const ApplicationsScreen(),
      const ContactsScreen(),
      const MetricsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Ofertas',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Postulaciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Contactos',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Metricas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<LookUpDataService>();
    final name =
        auth.profile?['nombre_completo']?.toString().split(' ').first ??
        'Postulante';
    final events = data.latestEvents();

    return RefreshIndicator(
      onRefresh: () async {
        final cuentaId = auth.cuentaId;
        if (cuentaId != null) {
          await context.read<LookUpDataService>().refresh(cuentaId);
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: kBrandGradient,
              borderRadius: BorderRadius.circular(26),
              boxShadow: softShadow(opacity: 0.30, blur: 28, y: 14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, $name',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tu busqueda laboral en un solo lugar.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Image.asset(
                    'assets/images/logo_lookup.png',
                    width: 52,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (data.error != null) ErrorBanner(message: data.error!),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: 'Ofertas',
                  value: data.jobs.length.toString(),
                  icon: Icons.work_outline,
                  color: kSkyBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricTile(
                  label: 'Postulaciones',
                  value: data.applications.length.toString(),
                  icon: Icons.fact_check_outlined,
                  color: kBrandBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ActionTile(
                  icon: Icons.search,
                  title: 'Explorar ofertas',
                  onTap: () => onOpenTab(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ActionTile(
                  icon: Icons.timeline,
                  title: 'Ver avance',
                  onTap: () => onOpenTab(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Avisos recientes',
            actionLabel: 'Ver todo',
            onAction: () => onOpenTab(2),
          ),
          const SizedBox(height: 10),
          if (events.isEmpty)
            const EmptyState(
              icon: Icons.notifications_none,
              title: 'Aun no hay novedades',
              message:
                  'Cuando una empresa actualice una postulacion, aparecera aqui.',
            )
          else
            ...events.map((event) => EventCard(event: event)),
        ],
      ),
    );
  }
}

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<LookUpDataService>();
    final filtered = data.jobs.where((job) {
      final text = '${job['titulo']} ${job['descripcion']} ${job['ubicacion']}'
          .toLowerCase();
      return text.contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Ofertas')),
      body: RefreshIndicator(
        onRefresh: () => context.read<LookUpDataService>().fetchJobs(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Buscar por puesto, ciudad o descripcion',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 14),
            if (data.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              const EmptyState(
                icon: Icons.work_off_outlined,
                title: 'No hay ofertas disponibles',
                message: 'Vuelve a revisar pronto o cambia tu busqueda.',
              )
            else
              ...filtered.map((job) {
                final puestoId = job['puesto_id']?.toString() ?? '';
                final alreadyApplied = data.hasAppliedTo(puestoId);
                return JobCard(
                  job: job,
                  alreadyApplied: alreadyApplied,
                  onApply: alreadyApplied || auth.cuentaId == null
                      ? null
                      : () => _apply(context, auth.cuentaId!, puestoId),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _apply(
    BuildContext context,
    String cuentaId,
    String puestoId,
  ) async {
    try {
      await context.read<LookUpDataService>().applyToJob(cuentaId, puestoId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Postulacion enviada.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }
}

class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<LookUpDataService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis postulaciones')),
      body: RefreshIndicator(
        onRefresh: () async {
          final cuentaId = auth.cuentaId;
          if (cuentaId != null) {
            await context.read<LookUpDataService>().fetchApplications(cuentaId);
          }
        },
        child: data.applications.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(18),
                children: const [
                  EmptyState(
                    icon: Icons.fact_check_outlined,
                    title: 'Todavia no postulaste',
                    message: 'Explora ofertas y envia tu primera postulacion.',
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                itemCount: data.applications.length,
                itemBuilder: (context, index) {
                  final application = data.applications[index];
                  final postulacionId =
                      application['postulacion_id']?.toString() ?? '';
                  return ApplicationCard(
                    application: application,
                    contacts: data.contactsFor(postulacionId),
                  );
                },
              ),
      ),
    );
  }
}

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<LookUpDataService>();
    final threads = data.applications.where((application) {
      final postulacionId = application['postulacion_id']?.toString() ?? '';
      return data.contactsFor(postulacionId).isNotEmpty;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Contactos')),
      body: RefreshIndicator(
        onRefresh: () async {
          final cuentaId = auth.cuentaId;
          if (cuentaId != null) {
            await context.read<LookUpDataService>().fetchApplications(cuentaId);
          }
        },
        child: threads.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(18),
                children: const [
                  EmptyState(
                    icon: Icons.forum_outlined,
                    title: 'Aun no tienes mensajes',
                    message:
                        'Cuando una empresa te escriba sobre una postulacion, aparecera aqui.',
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                itemCount: threads.length,
                itemBuilder: (context, index) {
                  final application = threads[index];
                  final postulacionId =
                      application['postulacion_id']?.toString() ?? '';
                  return ContactThreadCard(
                    application: application,
                    contacts: data.contactsFor(postulacionId),
                  );
                },
              ),
      ),
    );
  }
}

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<LookUpDataService>();
    final metrics = data.metrics ?? const <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(title: const Text('Metricas')),
      body: RefreshIndicator(
        onRefresh: () async {
          final cuentaId = auth.cuentaId;
          if (cuentaId != null) {
            await context.read<LookUpDataService>().fetchMetrics(cuentaId);
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Text(
              'Resumen de tu proceso',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: kInk,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Indicadores de tu actividad en la plataforma.',
              style: TextStyle(color: kInkMuted, height: 1.35),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 620 ? 4 : 2,
              shrinkWrap: true,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: [
                MetricTile(
                  label: 'Postulaciones',
                  value: '${metrics['total_postulaciones'] ?? 0}',
                  icon: Icons.send_outlined,
                  color: kBrandBlue,
                ),
                MetricTile(
                  label: 'Entrevistas',
                  value: '${metrics['total_entrevistas'] ?? 0}',
                  icon: Icons.event_available_outlined,
                  color: kSkyBlue,
                ),
                MetricTile(
                  label: 'Ofertas',
                  value: '${metrics['total_exitos'] ?? 0}',
                  icon: Icons.emoji_events_outlined,
                  color: Colors.green,
                ),
                MetricTile(
                  label: 'Rechazos',
                  value: '${metrics['total_rechazos'] ?? 0}',
                  icon: Icons.close_outlined,
                  color: Colors.redAccent,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Tasa de exito'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.trending_up_rounded,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Porcentaje de exito en postulaciones',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: kInkMuted,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                        Text(
                          '${((metrics['tasa_exito'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: kBrandBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 12,
                        backgroundColor: kBrandBlue.withValues(alpha: 0.10),
                        valueColor: const AlwaysStoppedAnimation(kSkyBlue),
                        value:
                            ((metrics['tasa_exito'] as num?)?.toDouble() ?? 0)
                                .clamp(0, 100) /
                            100,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final profile = auth.profile ?? const <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => EditProfileDialog(profile: profile),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 26, 18, 24),
            decoration: BoxDecoration(
              gradient: kBrandGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: softShadow(opacity: 0.30, blur: 28, y: 14),
            ),
            child: Column(
              children: [
                ProfileAvatar(
                  fotoUrl: profile['foto_url']?.toString(),
                  onGradient: true,
                ),
                const SizedBox(height: 14),
                Text(
                  profile['nombre_completo']?.toString() ?? 'Postulante',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile['email']?.toString() ?? '',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Subir foto'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 1.4,
                    ),
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => PhotoUploadDialog(
                      currentUrl: profile['foto_url']?.toString(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Datos personales'),
          const SizedBox(height: 8),
          InfoRow(
            icon: Icons.school_outlined,
            label: 'Carrera',
            value: profile['carrera']?.toString() ?? 'No especificada',
          ),
          InfoRow(
            icon: Icons.phone_outlined,
            label: 'Telefono',
            value: profile['telefono']?.toString() ?? 'No especificado',
          ),
          InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Ciudad',
            value: profile['ciudad']?.toString() ?? 'No especificada',
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesion'),
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (context.mounted) {
                context.read<LookUpDataService>().clear();
              }
            },
          ),
        ],
      ),
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key, required this.profile});

  final Map<String, dynamic> profile;

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _careerController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.profile['nombre_completo']?.toString() ?? '',
    );
    _careerController = TextEditingController(
      text: widget.profile['carrera']?.toString() ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.profile['telefono']?.toString() ?? '',
    );
    _cityController = TextEditingController(
      text: widget.profile['ciudad']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _careerController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar perfil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _careerController,
              decoration: const InputDecoration(labelText: 'Carrera'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Telefono'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'Ciudad'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await context.read<AuthService>().updateProfile({
        'nombre_completo': _nameController.text.trim(),
        'carrera': _careerController.text.trim(),
        'telefono': _phoneController.text.trim(),
        'ciudad': _cityController.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class PhotoUploadDialog extends StatefulWidget {
  const PhotoUploadDialog({super.key, this.currentUrl});

  final String? currentUrl;

  @override
  State<PhotoUploadDialog> createState() => _PhotoUploadDialogState();
}

class _PhotoUploadDialogState extends State<PhotoUploadDialog> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _previewBytes;
  String? _error;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 86,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.length > 3 * 1024 * 1024) {
      setState(() => _error = 'La imagen no debe superar 3 MB.');
      return;
    }
    setState(() {
      _selectedImage = picked;
      _previewBytes = bytes;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_selectedImage == null) {
      setState(() => _error = 'Selecciona una imagen primero.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final success = await context.read<AuthService>().uploadProfilePhoto(
        _selectedImage!,
      );
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() => _error = 'No se pudo subir la foto.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.currentUrl?.trim();
    final hasCurrent = current != null && current.isNotEmpty;

    return AlertDialog(
      title: const Text('Subir foto de perfil'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: kBrandBlue.withValues(alpha: 0.12),
              backgroundImage: _previewBytes != null
                  ? MemoryImage(_previewBytes!)
                  : hasCurrent
                  ? NetworkImage(current) as ImageProvider
                  : null,
              child: _previewBytes == null && !hasCurrent
                  ? const Icon(Icons.person, color: kBrandBlue, size: 44)
                  : null,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(
                _selectedImage == null
                    ? 'Seleccionar imagen'
                    : 'Cambiar seleccion',
              ),
              onPressed: _isSaving ? null : _pickImage,
            ),
            const SizedBox(height: 8),
            const Text(
              'Formatos admitidos: JPG, PNG, WEBP o GIF.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kInkMuted, fontSize: 12),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Subir'),
        ),
      ],
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.fotoUrl,
    this.onGradient = false,
  });

  final String? fotoUrl;
  final bool onGradient;

  @override
  Widget build(BuildContext context) {
    final url = fotoUrl?.trim();
    return Container(
      padding: EdgeInsets.all(onGradient ? 4 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onGradient ? Colors.white.withValues(alpha: 0.25) : null,
        border: onGradient
            ? Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2)
            : null,
        boxShadow: onGradient
            ? null
            : softShadow(opacity: 0.18, blur: 18, y: 8),
      ),
      child: CircleAvatar(
        radius: 42,
        backgroundColor: onGradient ? kBrandBlueAlt : kBrandBlue,
        backgroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
        onBackgroundImageError: url == null || url.isEmpty
            ? null
            : (exception, stackTrace) {},
        child: url == null || url.isEmpty
            ? const Icon(Icons.person, color: Colors.white, size: 42)
            : null,
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.alreadyApplied,
    required this.onApply,
  });

  final Map<String, dynamic> job;
  final bool alreadyApplied;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    job['titulo']?.toString() ?? 'Oferta sin titulo',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kInk,
                    ),
                  ),
                ),
                StatusChip(label: job['estado']?.toString() ?? 'abierto'),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                IconText(
                  icon: Icons.location_on_outlined,
                  text:
                      job['ubicacion']?.toString() ??
                      'Ubicacion no especificada',
                ),
                IconText(
                  icon: Icons.badge_outlined,
                  text: _contractLabel(job['tipo_contrato']?.toString()),
                ),
              ],
            ),
            if (job['descripcion'] != null) ...[
              const SizedBox(height: 10),
              Text(
                job['descripcion'].toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kInkMuted, height: 1.4),
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: kBrandBlue,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _salary(job),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: kInk,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onApply,
                  style: alreadyApplied
                      ? FilledButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.15),
                          foregroundColor: Colors.green.shade700,
                        )
                      : null,
                  icon: Icon(
                    alreadyApplied ? Icons.check_circle : Icons.send_rounded,
                    size: 18,
                  ),
                  label: Text(alreadyApplied ? 'Postulado' : 'Postular'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ApplicationCard extends StatelessWidget {
  const ApplicationCard({
    super.key,
    required this.application,
    required this.contacts,
  });

  final Map<String, dynamic> application;
  final List<Map<String, dynamic>> contacts;

  @override
  Widget build(BuildContext context) {
    final puesto = _asMap(application['puesto']);
    final empresa = _asMap(application['empresa']);
    final hitos = _asMapList(application['hitos']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        puesto['titulo']?.toString() ?? 'Puesto',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: kInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        empresa['nombre']?.toString() ??
                            'Empresa no especificada',
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: application['estado']?.toString() ?? 'pendiente',
                ),
              ],
            ),
            const SizedBox(height: 12),
            IconText(
              icon: Icons.calendar_today_outlined,
              text:
                  'Postulado: ${_formatDate(application['fecha_postulacion'])}',
            ),
            if (hitos.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.timeline, size: 16, color: kBrandBlue),
                  const SizedBox(width: 6),
                  Text(
                    'AVANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: kInkMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Timeline(items: hitos.take(3).toList(), formatDate: _formatDate),
            ],
            if (contacts.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.mark_chat_read_outlined,
                    size: 16,
                    color: kBrandBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'FEEDBACK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: kInkMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...contacts.take(2).map((contacto) {
                final feedback = _asMap(contacto['ultimo_feedback']);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: IconText(
                    icon: Icons.mark_email_read_outlined,
                    text:
                        feedback['mensaje']?.toString() ??
                        'La empresa envio feedback.',
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.items, required this.formatDate});

  final List<Map<String, dynamic>> items;
  final String Function(dynamic) formatDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (i) {
        final hito = items[i];
        final isLast = i == items.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: kBrandBlue, width: 3),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: kHairline,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatDate(hito['fecha']),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: kInkMuted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hito['descripcion']?.toString() ?? 'Actualizacion',
                        style: const TextStyle(color: kInk, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class ContactThreadCard extends StatelessWidget {
  const ContactThreadCard({
    super.key,
    required this.application,
    required this.contacts,
  });

  final Map<String, dynamic> application;
  final List<Map<String, dynamic>> contacts;

  @override
  Widget build(BuildContext context) {
    final puesto = _asMap(application['puesto']);
    final empresa = _asMap(application['empresa']);
    final latest = contacts.isEmpty ? const <String, dynamic>{} : contacts.last;
    final latestFeedback = _asMap(latest['ultimo_feedback']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) =>
              ContactThreadSheet(application: application, contacts: contacts),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: kBrandBlue.withValues(alpha: 0.1),
                child: const Icon(Icons.business_outlined, color: kBrandBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      puesto['titulo']?.toString() ?? 'Postulacion',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: kInk,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      empresa['nombre']?.toString() ?? 'Empresa',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      latestFeedback['mensaje']?.toString() ??
                          'La empresa envio una actualizacion.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: kBrandBlue),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactThreadSheet extends StatefulWidget {
  const ContactThreadSheet({
    super.key,
    required this.application,
    required this.contacts,
  });

  final Map<String, dynamic> application;
  final List<Map<String, dynamic>> contacts;

  @override
  State<ContactThreadSheet> createState() => _ContactThreadSheetState();
}

class _ContactThreadSheetState extends State<ContactThreadSheet> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<LookUpDataService>();
    final puesto = _asMap(widget.application['puesto']);
    final empresa = _asMap(widget.application['empresa']);
    final postulacionId =
        widget.application['postulacion_id']?.toString() ?? '';
    final contacts = data.contactsFor(postulacionId).isEmpty
        ? widget.contacts
        : data.contactsFor(postulacionId);

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.74,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            puesto['titulo']?.toString() ?? 'Postulacion',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kInk,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            empresa['nombre']?.toString() ?? 'Empresa',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) =>
                      ContactBubble(contact: contacts[index]),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  bottom: 14 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Responder a la empresa',
                          prefixIcon: Icon(Icons.chat_bubble_outline),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Enviar',
                      onPressed: _isSending || auth.cuentaId == null
                          ? null
                          : () => _send(context, auth.cuentaId!, postulacionId),
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _send(
    BuildContext context,
    String cuentaId,
    String postulacionId,
  ) async {
    final message = _messageController.text.trim();
    if (message.isEmpty || postulacionId.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await context.read<LookUpDataService>().sendContactMessage(
        cuentaId,
        postulacionId,
        message,
      );
      _messageController.clear();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}

class ContactBubble extends StatelessWidget {
  const ContactBubble({super.key, required this.contact});

  final Map<String, dynamic> contact;

  @override
  Widget build(BuildContext context) {
    final feedback = _asMap(contact['ultimo_feedback']);
    final tipo = feedback['tipo']?.toString() ?? 'comentario';
    final mensaje =
        feedback['mensaje']?.toString() ??
        'La empresa envio una actualizacion.';
    final motivo = feedback['motivo_rechazo']?.toString();
    final isMine = contact['remitente_rol']?.toString() == 'postulante';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 10,
          left: isMine ? 34 : 0,
          right: isMine ? 0 : 34,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine ? kBrandBlue.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: Radius.circular(isMine ? 8 : 0),
            bottomRight: Radius.circular(isMine ? 0 : 8),
          ),
          border: Border.all(color: kBrandBlue.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _feedbackLabel(tipo),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: kBrandBlue,
              ),
            ),
            const SizedBox(height: 6),
            Text(mensaje, style: const TextStyle(color: kInk)),
            if (motivo != null && motivo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Motivo: $motivo',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              _formatDate(contact['fecha_hora']),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  String _feedbackLabel(String tipo) {
    const labels = {
      'comentario': 'COMENTARIO',
      'aprobacion': 'APROBACION',
      'rechazo': 'RECHAZO',
      'otro': 'OTRO',
    };
    return labels[tipo] ?? tipo.toUpperCase();
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: softShadow(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: kInk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kInkMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 8,
      shadowColor: kBrandBlue.withValues(alpha: 0.10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kBrandBlue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: kBrandBlue),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: kInkMuted.withValues(alpha: 0.7),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: kInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kSkyBlue.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.notifications_outlined, color: kBrandBlue),
        ),
        title: Text(
          event['title']?.toString() ?? 'Actualizacion',
          style: const TextStyle(fontWeight: FontWeight.w700, color: kInk),
        ),
        subtitle: Text(
          event['description']?.toString() ?? '',
          style: const TextStyle(color: kInkMuted),
        ),
        trailing: Text(
          _formatDate(event['date']),
          style: const TextStyle(color: kInkMuted, fontSize: 12),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kBrandBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: kBrandBlue, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: kInkMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kInk,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2, top: 2, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 20,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              gradient: kBrandGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kInk,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kBrandBlue.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: kBrandBlue),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: kInk,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kInkMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD3D3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE0E0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Color(0xFFD23B3B),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB42525),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IconText extends StatelessWidget {
  const IconText({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 5),
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'aceptado' || 'oferta' => Colors.green,
      'rechazado' || 'rechazo' => Colors.redAccent,
      'entrevista' || 'en_revision' => Colors.orange,
      'cerrado' => Colors.grey,
      _ => kBrandBlue,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

String? _required(String? value, String message) {
  if (value == null || value.trim().isEmpty) return message;
  return null;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is List) {
    return value.map(_asMap).toList();
  }
  return <Map<String, dynamic>>[];
}

String _contractLabel(String? value) {
  if (value == null || value.isEmpty) return 'Contrato no especificado';
  return value.replaceAll('_', ' ');
}

String _salary(Map<String, dynamic> job) {
  final min = job['salario_min'];
  final max = job['salario_max'];
  final moneda = job['moneda']?.toString() ?? 'MXN';
  if (min == null && max == null) return 'Salario no especificado';
  if (min != null && max != null) return '$min - $max $moneda';
  return '${min ?? max} $moneda';
}

String _formatDate(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return '';
  final date = DateTime.tryParse(text);
  if (date == null) return text;
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
