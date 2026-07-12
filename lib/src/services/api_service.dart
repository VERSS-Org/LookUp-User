import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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
  /// URL base del backend. Sobreescribible en compilacion con:
  /// flutter run --dart-define=LOOKUP_API_BASE_URL=https://mi-backend/api/
  /// (en Android Emulator usa http://10.0.2.2:8000; en dispositivo fisico,
  /// la IP LAN de la PC que corre el backend).
  static const String _defaultBaseUrl = String.fromEnvironment(
    'LOOKUP_API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/',
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

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      _baseUri.resolve(endpoint),
      headers: _headers(),
    );
    return _processResponse(
      await _retryIfUnauthorized(
        response,
        () => http.get(_baseUri.resolve(endpoint), headers: _headers()),
      ),
    );
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool retryOnUnauthorized = true,
  }) async {
    Future<http.Response> send() async {
      var response = await http.post(
        _baseUri.resolve(endpoint),
        headers: _headers(),
        body: jsonEncode(body),
      );

      // http no reenvia el POST en redirecciones 307/308 (p. ej. barra final).
      if (response.statusCode == 307 || response.statusCode == 308) {
        final location = response.headers['location'];
        if (location != null) {
          final redirectUri =
              response.request?.url.resolve(location) ??
              _baseUri.resolve(location);
          response = await http.post(
            redirectUri,
            headers: _headers(),
            body: jsonEncode(body),
          );
        }
      }
      return response;
    }

    final response = await send();
    if (!retryOnUnauthorized) return _processResponse(response);
    return _processResponse(await _retryIfUnauthorized(response, send));
  }

  Future<dynamic> delete(String endpoint) async {
    Future<http.Response> send() =>
        http.delete(_baseUri.resolve(endpoint), headers: _headers());
    final response = await send();
    return _processResponse(await _retryIfUnauthorized(response, send));
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    Future<http.Response> send() => http.patch(
      _baseUri.resolve(endpoint),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final response = await send();
    return _processResponse(await _retryIfUnauthorized(response, send));
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
          : jsonDecode(utf8.decode(response.bodyBytes));
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
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
