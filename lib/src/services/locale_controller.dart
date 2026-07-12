import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lookup_user/src/i18n/strings.dart';

/// Idioma de la interfaz (es/en) persistido localmente.
class LocaleController with ChangeNotifier {
  static const _prefKey = 'appLanguage';

  String _language = 'es';
  String get language => _language;

  LocaleController() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved == 'en' || saved == 'es') {
      _language = saved!;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String language) async {
    if (language == _language) return;
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, language);
  }

  /// Traduce una clave; si falta en inglés cae al español y, en último caso,
  /// devuelve la clave (asi una clave faltante nunca rompe la UI).
  String t(String key) {
    if (_language == 'en') {
      return stringsEn[key] ?? stringsEs[key] ?? key;
    }
    return stringsEs[key] ?? key;
  }
}

extension LocaleX on BuildContext {
  /// Acceso corto a las traducciones: `context.t('nav.home')`.
  /// Usa `watch` para que los textos se actualicen al cambiar el idioma.
  String t(String key) => watch<LocaleController>().t(key);

  /// Variante sin suscripción, para callbacks y código fuera de build.
  String tr(String key) => read<LocaleController>().t(key);
}
