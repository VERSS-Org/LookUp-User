import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lookup_user/src/services/api_service.dart';
import 'package:lookup_user/src/utils/formatters.dart';

/// Datos del postulante: vacantes, postulaciones, mensajes, métricas y logros.
class LookUpDataService with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _inbox = [];
  final Map<String, List<Map<String, dynamic>>> _threads = {};
  Map<String, dynamic>? _metrics;
  List<Map<String, dynamic>> _achievements = [];
  String? _achievementsError;
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _recommendedJobs = [];
  List<Map<String, dynamic>> _recommendedCompanies = [];
  List<Map<String, dynamic>> _savedJobs = [];
  List<Map<String, dynamic>> _followedCompanies = [];
  String _searchQuery = '';
  final Map<String, List<Map<String, dynamic>>> _companySearchCache = {};
  bool _isLoading = false;
  String? _error;
  int _processAlerts = 0;
  int _unseenNotifications = 0;
  int _generation = 0;

  List<Map<String, dynamic>> get jobs => _jobs;
  List<Map<String, dynamic>> get applications => _applications;
  List<Map<String, dynamic>> get inbox => _inbox;
  Map<String, dynamic>? get metrics => _metrics;
  List<Map<String, dynamic>> get achievements => _achievements;
  String? get achievementsError => _achievementsError;
  List<Map<String, dynamic>> get events => _events;
  List<Map<String, dynamic>> get recommendedJobs => _recommendedJobs;
  List<Map<String, dynamic>> get recommendedCompanies => _recommendedCompanies;
  List<Map<String, dynamic>> get savedJobs => _savedJobs;
  List<Map<String, dynamic>> get followedCompanies => _followedCompanies;
  String get searchQuery => _searchQuery;
  int get unseenNotifications => _unseenNotifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Mensajes sin leer en toda la bandeja (para el badge del appbar).
  int get unreadMessages =>
      _inbox.fold(0, (total, hilo) => total + asInt(hilo['no_leidos']));

  /// Postulaciones cuyo estado cambio desde la ultima visita a Procesos.
  int get processAlerts => _processAlerts;

  List<Map<String, dynamic>> threadFor(String postulacionId) {
    return _threads[postulacionId] ?? const <Map<String, dynamic>>[];
  }

  void clear() {
    _generation++;
    _jobs = [];
    _applications = [];
    _inbox = [];
    _threads.clear();
    _metrics = null;
    _achievements = [];
    _achievementsError = null;
    _events = [];
    _recommendedJobs = [];
    _recommendedCompanies = [];
    _savedJobs = [];
    _followedCompanies = [];
    _searchQuery = '';
    _companySearchCache.clear();
    _unseenNotifications = 0;
    _error = null;
    _isLoading = false;
    _processAlerts = 0;
    notifyListeners();
  }

  Future<void> refresh(String cuentaId) async {
    final generation = _generation;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final errors = <String>[];
    Future<void> capture(Future<void> request) async {
      try {
        await request;
      } catch (error) {
        errors.add(error.toString());
      }
    }

    await Future.wait([
      capture(fetchJobs(notify: false)),
      capture(fetchApplications(cuentaId, notify: false)),
      capture(fetchMetrics(cuentaId, notify: false)),
      capture(fetchInbox(notify: false)),
      capture(fetchEvents(notify: false)),
    ]);
    // Estas funciones enriquecen la experiencia pero no deben impedir el uso
    // principal si un despliegue antiguo todavía no expone alguna ruta.
    await Future.wait([
      _captureOptional(() => fetchSavedJobs(notify: false)),
      _captureOptional(() => fetchFollowedCompanies(notify: false)),
      _captureOptional(() => fetchRecommendations(notify: false)),
    ]);

    if (generation != _generation) return;
    if (errors.isNotEmpty) {
      _error = errors.first;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _captureOptional(Future<void> Function() request) async {
    try {
      await request();
    } catch (error) {
      debugPrint('Optional LookUp data unavailable: $error');
    }
  }

  Future<void> fetchJobs({bool notify = true}) async {
    final generation = _generation;
    final response = await _api.get('puesto/?estado=abierto');
    if (generation != _generation) return;
    _jobs = asMapList(response);
    if (notify) notifyListeners();
  }

  /// Trae el detalle completo de una vacante (incluye requisitos actualizados).
  Future<Map<String, dynamic>?> fetchJobDetail(String puestoId) async {
    return asMap(await _api.get('puesto/$puestoId'));
  }

  /// Perfil publico de una cuenta (empresa o postulante).
  Future<Map<String, dynamic>?> fetchCuenta(String cuentaId) async {
    return asMap(await _api.get('iam/cuenta/$cuentaId'));
  }

  /// Vacantes abiertas de una empresa concreta.
  Future<List<Map<String, dynamic>>> fetchJobsByCompany(
    String empresaId,
  ) async {
    final response = await _api.get(
      'puesto/?empresa_id=$empresaId&estado=abierto',
    );
    return asMapList(response);
  }

  Future<void> fetchApplications(String cuentaId, {bool notify = true}) async {
    final generation = _generation;
    final response = await _api.get('postulacion/?candidato_id=$cuentaId');
    if (generation != _generation) return;
    final applications = asMapList(response);
    final processAlerts = await _readProcessAlerts(applications, generation);
    if (generation != _generation) return;
    _applications = applications;
    _processAlerts = processAlerts;
    if (notify) notifyListeners();
  }

  Future<void> fetchMetrics(String cuentaId, {bool notify = true}) async {
    final generation = _generation;
    final metrics = asMap(await _api.get('metricas/resumen/$cuentaId'));
    if (generation != _generation) return;
    try {
      final achievements = asMapList(
        await _api.get('metricas/logros/$cuentaId'),
      );
      if (generation != _generation) return;
      _achievements = achievements;
      _achievementsError = null;
    } catch (error) {
      debugPrint('Error fetching achievements: $error');
      if (generation != _generation) return;
      _achievementsError = error.toString();
    }
    if (generation != _generation) return;
    _metrics = metrics;
    if (notify) notifyListeners();
  }

  // ---- Mensajeria ----------------------------------------------------------

  Future<void> fetchInbox({bool notify = true}) async {
    final generation = _generation;
    final response = await _api.get('contacto/bandeja');
    if (generation != _generation) return;
    _inbox = asMapList(response);
    if (notify) notifyListeners();
  }

  Future<void> fetchThread(String postulacionId, {bool notify = true}) async {
    final generation = _generation;
    final response = await _api.get('contacto/?postulacion_id=$postulacionId');
    if (generation != _generation) return;
    _threads[postulacionId] = asMapList(response);
    if (notify) notifyListeners();
  }

  Future<void> sendChatMessage(String postulacionId, String texto) async {
    final generation = _generation;
    await _api.post('contacto/mensaje', {
      'postulacion_id': postulacionId,
      'mensaje_texto': texto,
    });
    if (generation != _generation) return;
    await fetchThread(postulacionId, notify: false);
    if (generation != _generation) return;
    await fetchInbox(notify: false);
    if (generation != _generation) return;
    notifyListeners();
  }

  Future<void> markThreadRead(String postulacionId) async {
    final generation = _generation;
    try {
      await _api.post('contacto/marcar-leidos', {
        'postulacion_id': postulacionId,
      });
      if (generation != _generation) return;
      for (final hilo in _inbox) {
        if (hilo['postulacion_id']?.toString() == postulacionId) {
          hilo['no_leidos'] = 0;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking thread read: $e');
    }
  }

  // ---- Alertas de cambios de estado ---------------------------------------

  static const _estadoSnapshotKey = 'estadoSnapshot';

  Future<int> _readProcessAlerts(
    List<Map<String, dynamic>> applications,
    int generation,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (generation != _generation) return 0;
    final raw = prefs.getString(_estadoSnapshotKey);
    Map<String, dynamic> snapshot = {};
    if (raw != null) {
      try {
        snapshot = Map<String, dynamic>.from(jsonDecode(raw));
      } catch (_) {}
    }

    var alerts = 0;
    for (final application in applications) {
      final id = application['postulacion_id']?.toString();
      final estado = application['estado']?.toString();
      if (id == null || estado == null) continue;
      final previo = snapshot[id]?.toString();
      if (previo != null && previo != estado) alerts++;
    }
    return alerts;
  }

  /// Marca los estados actuales como vistos (al abrir la pestaña Procesos).
  Future<void> markProcessesSeen() async {
    final generation = _generation;
    final snapshot = <String, String>{};
    for (final application in _applications) {
      final id = application['postulacion_id']?.toString();
      final estado = application['estado']?.toString();
      if (id != null && estado != null) snapshot[id] = estado;
    }
    final prefs = await SharedPreferences.getInstance();
    if (generation != _generation) return;
    await prefs.setString(_estadoSnapshotKey, jsonEncode(snapshot));
    if (generation != _generation) return;
    if (_processAlerts != 0) {
      _processAlerts = 0;
      notifyListeners();
    }
  }

  // ---- Postulacion ---------------------------------------------------------

  Future<void> applyToJob(String cuentaId, String puestoId) async {
    final generation = _generation;
    await _api.post('postulacion/', {
      'candidato_id': cuentaId,
      'puesto_id': puestoId,
      'documentos_adjuntos': <Map<String, dynamic>>[],
    });
    if (generation != _generation) return;
    await refresh(cuentaId);
  }

  bool hasAppliedTo(String puestoId) {
    return _applications.any((application) {
      final puesto = asMap(application['puesto']);
      return application['puesto_id']?.toString() == puestoId ||
          puesto['puesto_id']?.toString() == puestoId;
    });
  }

  // ---- Guardados, empresas seguidas y recomendaciones ---------------------

  bool isJobSaved(String puestoId) => _savedJobs.any((item) {
    final puesto = asMap(item['puesto']);
    return item['puesto_id']?.toString() == puestoId ||
        puesto['puesto_id']?.toString() == puestoId;
  });

  bool isCompanyFollowed(String empresaId) => _followedCompanies.any((item) {
    final empresa = asMap(item['empresa']);
    return item['empresa_id']?.toString() == empresaId ||
        item['cuenta_id']?.toString() == empresaId ||
        empresa['cuenta_id']?.toString() == empresaId;
  });

  Future<void> fetchSavedJobs({bool notify = true}) async {
    final generation = _generation;
    final response = await _api.get('puesto/guardados');
    if (generation != _generation) return;
    _savedJobs = asMapList(response);
    if (notify) notifyListeners();
  }

  Future<void> toggleSavedJob(String puestoId) async {
    final generation = _generation;
    if (isJobSaved(puestoId)) {
      await _api.delete('puesto/guardados/$puestoId');
    } else {
      await _api.post('puesto/guardados/$puestoId', const {});
    }
    if (generation != _generation) return;
    await fetchSavedJobs(notify: false);
    try {
      // Guardar una vacante también ajusta las señales de afinidad del
      // recomendador, por lo que refrescamos sus resultados de inmediato.
      await fetchRecommendations(notify: false);
    } catch (error) {
      // La acción principal ya fue confirmada por la API; un fallo opcional
      // del recomendador no debe revertirla ni dejar el botón bloqueado.
      debugPrint('Could not refresh recommendations after save: $error');
    }
    if (generation == _generation) notifyListeners();
  }

  Future<void> fetchFollowedCompanies({bool notify = true}) async {
    final generation = _generation;
    final response = await _api.get('iam/empresas/seguidas');
    if (generation != _generation) return;
    _followedCompanies = asMapList(response);
    if (notify) notifyListeners();
  }

  Future<void> toggleFollowCompany(String empresaId) async {
    final generation = _generation;
    final wasFollowed = isCompanyFollowed(empresaId);
    if (wasFollowed) {
      await _api.delete('iam/empresas/seguidas/$empresaId');
    } else {
      await _api.post('iam/empresas/seguidas/$empresaId', const {});
    }
    if (generation != _generation) return;
    await fetchFollowedCompanies(notify: false);
    try {
      await fetchRecommendations(notify: false);
    } catch (error) {
      // Seguir/dejar de seguir ya se confirmó. Si el refresco opcional falla,
      // evita al menos recomendar de nuevo una empresa recién seguida.
      if (!wasFollowed) {
        _recommendedCompanies.removeWhere(
          (company) =>
              (company['cuenta_id'] ?? company['empresa_id'])?.toString() ==
              empresaId,
        );
      }
      debugPrint('Could not refresh recommendations after follow: $error');
    }
    if (generation == _generation) notifyListeners();
  }

  Future<void> fetchRecommendations({bool notify = true}) async {
    final generation = _generation;
    final responses = await Future.wait([
      _api.get('puesto/recomendados?limit=20'),
      _api.get('iam/empresas/recomendadas?limit=12'),
    ]);
    if (generation != _generation) return;
    _recommendedJobs = asMapList(responses[0]);
    _recommendedCompanies = asMapList(responses[1]);
    if (notify) notifyListeners();
  }

  // ---- Notificaciones (novedades de los ultimos 7 dias) --------------------

  static const _lastSeenNotifsKey = 'lastSeenNotifs';

  Future<void> fetchEvents({bool notify = true}) async {
    final generation = _generation;
    List<Map<String, dynamic>> events;
    try {
      events = asMapList(await _api.get('iam/notificaciones'));
    } on ApiException catch (error) {
      // Compatibilidad temporal con despliegues anteriores del backend.
      if (error.statusCode != 404) rethrow;
      events = asMapList(await _api.get('postulacion/eventos'));
    }
    if (generation != _generation) return;
    final unseen = await _readUnseenNotifications(events, generation);
    if (generation != _generation) return;
    _events = events;
    _unseenNotifications = unseen;
    if (notify) notifyListeners();
  }

  Future<int> _readUnseenNotifications(
    List<Map<String, dynamic>> events,
    int generation,
  ) async {
    if (events.any(
      (event) =>
          event.containsKey('leida') || event.containsKey('fecha_creacion'),
    )) {
      return events.where((event) => event['leida'] != true).length;
    }
    final prefs = await SharedPreferences.getInstance();
    if (generation != _generation) return 0;
    final lastSeen = prefs.getString(_lastSeenNotifsKey) ?? '';
    return events
        .where((e) => (e['fecha']?.toString() ?? '').compareTo(lastSeen) > 0)
        .length;
  }

  /// Marca las notificaciones actuales cuando el usuario elige leerlas.
  Future<void> markNotificationsSeen() async {
    final generation = _generation;
    if (_events.isEmpty && _unseenNotifications == 0) return;
    try {
      await _api.patch('iam/notificaciones/leer-todas', const {});
    } on ApiException catch (error) {
      if (error.statusCode != 404) rethrow;
    }
    final prefs = await SharedPreferences.getInstance();
    final latest = _events
        .map((e) => (e['fecha'] ?? e['fecha_creacion'])?.toString() ?? '')
        .fold('', (a, b) => a.compareTo(b) >= 0 ? a : b);
    if (generation != _generation) return;
    if (latest.isNotEmpty) {
      await prefs.setString(_lastSeenNotifsKey, latest);
    }
    if (generation != _generation) return;
    if (_unseenNotifications != 0) {
      _unseenNotifications = 0;
      notifyListeners();
    }
  }

  /// Marca una notificación concreta sin consumir el resto del buzón.
  ///
  /// Los eventos del endpoint legado no incluyen un identificador persistente;
  /// en ese caso se conserva la compatibilidad marcando el conjunto actual.
  Future<void> markNotificationSeen(Map<String, dynamic> event) async {
    if (event['leida'] == true) return;
    final notificationId = event['notificacion_id']?.toString().trim() ?? '';
    if (notificationId.isEmpty) {
      await markNotificationsSeen();
      return;
    }

    final generation = _generation;
    try {
      await _api.patch(
        'iam/notificaciones/${Uri.encodeComponent(notificationId)}/leida',
        const {},
      );
    } on ApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      await markNotificationsSeen();
      return;
    }
    if (generation != _generation) return;

    _events = [
      for (final item in _events)
        if (item['notificacion_id']?.toString() == notificationId)
          {...item, 'leida': true}
        else
          item,
    ];
    _unseenNotifications = _events
        .where((item) => item['leida'] != true)
        .length;
    notifyListeners();
  }

  // ---- Buscador de empresas -------------------------------------------------

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> searchCompanies(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) return [];
    final cached = _companySearchCache[normalized];
    if (cached != null) return cached;
    final generation = _generation;

    final q = Uri.encodeQueryComponent(query.trim());
    final results = asMapList(await _api.get('iam/empresas?q=$q'));
    if (generation != _generation) return [];
    if (_companySearchCache.length >= 20) {
      _companySearchCache.remove(_companySearchCache.keys.first);
    }
    _companySearchCache[normalized] = results;
    return results;
  }

  Future<List<Map<String, dynamic>>> searchOrganizations(String query) async {
    final normalized = query.trim();
    if (normalized.length < 2) return const [];
    final q = Uri.encodeQueryComponent(normalized);
    return asMapList(await _api.get('iam/organizaciones?q=$q&limit=10'));
  }

  // ---- Retiro de postulacion ------------------------------------------------

  static const estadosRetirables = {'pendiente', 'en_revision', 'entrevista'};

  Future<void> withdrawApplication(
    String cuentaId,
    String postulacionId,
  ) async {
    final generation = _generation;
    await _api.delete('postulacion/$postulacionId');
    if (generation != _generation) return;
    await refresh(cuentaId);
  }
}
