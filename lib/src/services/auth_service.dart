import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lookup_user/src/services/api_service.dart';
import 'package:lookup_user/src/utils/formatters.dart';

/// Sesion y perfil del postulante autenticado.
class AuthService with ChangeNotifier {
  final ApiService _api = ApiService();

  String? _token;
  String? _refreshToken;
  String? _cuentaId;
  String? _role;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  Future<bool>? _refreshInFlight;
  int _sessionGeneration = 0;
  bool _passwordChangedNotice = false;

  bool get isAuthenticated =>
      _token != null && _cuentaId != null && _role == 'postulante';
  bool get isLoading => _isLoading;
  String? get cuentaId => _cuentaId;
  String? get role => _role;
  Map<String, dynamic>? get profile => _profile;

  bool consumePasswordChangedNotice() {
    if (!_passwordChangedNotice) return false;
    _passwordChangedNotice = false;
    return true;
  }

  AuthService() {
    _api.setRefreshTokenHandler(refreshAccessToken);
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');
    final savedCuentaId = prefs.getString('cuentaId');
    final savedRefreshToken = prefs.getString('refreshToken');

    if (savedToken == null ||
        savedToken.isEmpty ||
        savedCuentaId == null ||
        savedCuentaId.isEmpty ||
        savedRefreshToken == null ||
        savedRefreshToken.isEmpty) {
      await _clearSession();
      return false;
    }

    _token = savedToken;
    _refreshToken = savedRefreshToken;
    _cuentaId = savedCuentaId;
    _role = prefs.getString('role') ?? 'postulante';
    _api.setToken(_token);

    if (_role != 'postulante') {
      await logout();
      return false;
    }

    try {
      await fetchProfile();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      if (e.isConnectionError || (e.statusCode ?? 0) >= 500) rethrow;
      debugPrint('Stored session is not valid: $e');
    }

    try {
      if (await refreshAccessToken()) {
        await fetchProfile();
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      if (e.isConnectionError || (e.statusCode ?? 0) >= 500) rethrow;
      debugPrint('Stored session refresh failed: $e');
    }

    await logout();
    return false;
  }

  Future<bool> login(String email, String password) async {
    return _withLoading(() => _loginRequest(email, password));
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
      return _loginRequest(email, password);
    });
  }

  Future<void> fetchProfile() async {
    if (_cuentaId == null) return;
    _profile = asMap(await _api.get('iam/cuenta/$_cuentaId'));
    final profileRole = _profile?['rol']?.toString();
    if (profileRole != null && profileRole != 'postulante') {
      throw ApiException('La sesion restaurada no pertenece a un postulante.');
    }
    notifyListeners();
  }

  Future<bool> refreshAccessToken() async {
    final activeRefresh = _refreshInFlight;
    if (activeRefresh != null) return activeRefresh;

    final refresh = _performTokenRefresh();
    _refreshInFlight = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshInFlight, refresh)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<bool> _performTokenRefresh() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      if (_token != null) await _clearSession();
      return false;
    }
    final generation = _sessionGeneration;

    try {
      final response = asMap(
        await _api.post('iam/refresh-token', {
          'refresh_token': refreshToken,
        }, retryOnUnauthorized: false),
      );
      final newToken = response['access_token']?.toString();
      if (newToken == null || newToken.isEmpty) return false;
      if (generation != _sessionGeneration || _refreshToken == null) {
        return false;
      }

      _token = newToken;
      _api.setToken(newToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', newToken);
      return true;
    } on ApiException catch (e) {
      debugPrint('Token refresh error: $e');
      if (e.isUnauthorized && generation == _sessionGeneration) {
        await _clearSession();
      }
      if (e.isConnectionError || (e.statusCode ?? 0) >= 500) rethrow;
      return false;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      rethrow;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (_cuentaId == null) return false;

    return _withLoading(() async {
      _profile = asMap(await _api.patch('iam/cuenta/$_cuentaId', updates));
      notifyListeners();
      return true;
    });
  }

  Future<bool> changePassword(
    String passwordActual,
    String passwordNuevo,
  ) async {
    return _withLoading(() async {
      final response = asMap(
        await _api.post('iam/cambiar-password', {
          'password_actual': passwordActual,
          'password_nuevo': passwordNuevo,
        }),
      );
      final changed = response['exito'] == true;
      if (changed) {
        // El backend revoca ambos tokens al cambiar la contraseña.
        _passwordChangedNotice = true;
        await _clearSession();
      }
      return changed;
    });
  }

  Future<bool> uploadProfilePhoto(XFile file) async {
    if (_cuentaId == null) return false;

    return _withLoading(() async {
      _profile = asMap(
        await _api.uploadFile('iam/cuenta/$_cuentaId/foto', 'file', file),
      );
      notifyListeners();
      return true;
    });
  }

  Future<bool> uploadProfileBanner(XFile file) async {
    if (_cuentaId == null) return false;

    return _withLoading(() async {
      _profile = asMap(
        await _api.uploadFile('iam/cuenta/$_cuentaId/banner', 'banner', file),
      );
      notifyListeners();
      return true;
    });
  }

  Future<void> logout() => _clearSession();

  Future<void> _clearSession() async {
    _sessionGeneration++;
    _refreshInFlight = null;
    final prefs = await SharedPreferences.getInstance();
    for (final key in const {
      'token',
      'refreshToken',
      'cuentaId',
      'role',
      'estadoSnapshot',
      'lastSeenNotifs',
    }) {
      await prefs.remove(key);
    }
    _token = null;
    _refreshToken = null;
    _cuentaId = null;
    _role = null;
    _profile = null;
    _isLoading = false;
    _api.setToken(null);
    notifyListeners();
  }

  Future<bool> _loginRequest(String email, String password) async {
    final response = asMap(
      await _api.post('iam/login', {
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response['rol'] != 'postulante') {
      throw ApiException(
        'Esta cuenta no es de postulante. Usa la app LookUp Empresas.',
      );
    }

    await _saveSession(response);
    try {
      await fetchProfile();
      return true;
    } catch (_) {
      // El login solo se considera completo cuando la cuenta autenticada pudo
      // validarse. Evita dejar una sesión parcial ante un perfil inválido o
      // una respuesta incompleta del backend.
      await _clearSession();
      rethrow;
    }
  }

  Future<void> _saveSession(Map<String, dynamic> response) async {
    final token = response['access_token']?.toString();
    final refreshToken = response['refresh_token']?.toString();
    final cuentaId = response['cuenta_id']?.toString();
    final role = response['rol']?.toString();

    if (token == null ||
        token.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty ||
        cuentaId == null ||
        cuentaId.isEmpty ||
        role == null ||
        role != 'postulante') {
      throw ApiException('Respuesta de login incompleta.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('cuentaId', cuentaId);
    await prefs.setString('role', role);
    await prefs.setString('refreshToken', refreshToken);

    _sessionGeneration++;
    _refreshInFlight = null;
    _token = token;
    _refreshToken = refreshToken;
    _cuentaId = cuentaId;
    _role = role;
    _api.setToken(token);
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
