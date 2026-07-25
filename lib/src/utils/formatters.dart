/// Utilidades de conversion y formato compartidas por las pantallas.
library;

import 'package:flutter/widgets.dart';

import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/theme.dart';

/// Etiqueta traducida del tipo de contrato.
String contractLabelT(BuildContext context, String? value) {
  if (value == null || value.isEmpty) return context.tr('contrato.na');
  final key = 'contrato.$value';
  final label = context.tr(key);
  return label == key ? value.replaceAll('_', ' ') : label;
}

String modalityLabelT(BuildContext context, String? value) {
  if (value == null || value.isEmpty) return context.tr('modalidad.na');
  final normalized = value.toLowerCase().replaceAll('í', 'i');
  final key = 'modalidad.$normalized';
  final label = context.tr(key);
  return label == key ? value.replaceAll('_', ' ') : label;
}

String? requiredField(String? value, String message) {
  if (value == null || value.trim().isEmpty) return message;
  return null;
}

/// Valida los mismos requisitos de contrasena que exige el backend.
String? strongPassword(String? password) {
  final error = _strongPasswordError(password);
  return switch (error) {
    'min' => 'Minimo 8 caracteres.',
    'uppercase' => 'Incluye una letra mayuscula.',
    'lowercase' => 'Incluye una letra minuscula.',
    'number' => 'Incluye un numero.',
    'symbol' => 'Incluye un caracter especial.',
    _ => null,
  };
}

String? strongPasswordT(BuildContext context, String? password) {
  final error = _strongPasswordError(password);
  return error == null ? null : context.tr('auth.password.$error');
}

String? _strongPasswordError(String? password) {
  if (password == null || password.length < 8) {
    return 'min';
  }
  if (!password.contains(RegExp(r'[A-Z]'))) {
    return 'uppercase';
  }
  if (!password.contains(RegExp(r'[a-z]'))) {
    return 'lowercase';
  }
  if (!password.contains(RegExp(r'[0-9]'))) {
    return 'number';
  }
  if (!password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'))) {
    return 'symbol';
  }
  return null;
}

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is List) {
    return value.map(asMap).toList();
  }
  return <Map<String, dynamic>>[];
}

int asInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

/// Normaliza texto para busquedas locales tolerantes a mayusculas y tildes.
String normalizeSearchText(Object? value) {
  var text = value?.toString().trim().toLowerCase() ?? '';
  const replacements = {
    '\u00e1': 'a',
    '\u00e9': 'e',
    '\u00ed': 'i',
    '\u00f3': 'o',
    '\u00fa': 'u',
    '\u00fc': 'u',
    '\u00f1': 'n',
  };
  for (final entry in replacements.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }
  return text;
}

String contractLabel(String? value) {
  const labels = {
    'tiempo_completo': 'Jornada Completa',
    'medio_tiempo': 'Jornada Parcial',
    'temporal': 'Temporal',
    // Compatibilidad de lectura con vacantes antiguas.
    'freelance': 'Freelance',
    'practicas': 'Prácticas Preprofesionales',
  };
  if (value == null || value.isEmpty) return 'Contrato no especificado';
  return labels[value] ?? value.replaceAll('_', ' ');
}

String _formatAmount(num value) {
  final rounded = value.toDouble();
  final entero = rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toStringAsFixed(2);
  // Separador de miles simple: 12345 -> 12,345
  final partes = entero.split('.');
  final digits = partes.first;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0 && digits[i - 1] != '-') {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return partes.length > 1 ? '$buffer.${partes[1]}' : buffer.toString();
}

String salaryLabel(Map<String, dynamic> job) {
  final min = job['salario_min'];
  final max = job['salario_max'];
  final moneda = job['moneda']?.toString() ?? 'PEN';
  if (min == null && max == null) return 'Salario a convenir';
  if (min != null && max != null) {
    return '${_formatAmount(min as num)} - ${_formatAmount(max as num)} $moneda';
  }
  return '${_formatAmount((min ?? max) as num)} $moneda';
}

String salaryLabelT(BuildContext context, Map<String, dynamic> job) {
  if (job['salario_min'] == null && job['salario_max'] == null) {
    return context.tr('offers.salary.na');
  }
  return salaryLabel(job);
}

String formatDate(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return '';
  final date = DateTime.tryParse(text);
  if (date == null) return text;
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

/// Reemplaza los códigos de estado dentro de textos generados por el backend
/// ("Estado actualizado de pendiente a en_revision") por su etiqueta legible.
String prettyEventText(BuildContext context, String text) {
  final token = RegExp(
    r'\b(en_revision|pendiente|entrevista|aceptado|oferta|rechazado|rechazo)\b',
    caseSensitive: false,
  );
  return text.replaceAllMapped(token, (match) {
    final estado = canonicalEstado(match.group(0) ?? '');
    return context.tr('estado.$estado').toLowerCase();
  });
}

/// Presenta hitos nuevos usando sus campos estructurados y conserva soporte
/// para registros historicos que solo incluyen una descripcion libre.
String eventDescriptionT(BuildContext context, Map<String, dynamic> event) {
  String stateLabel(Object? raw) {
    final canonical = canonicalEstado(raw?.toString() ?? '');
    if (canonical.isEmpty) return '';
    final key = 'estado.$canonical';
    final translated = context.tr(key);
    return translated == key ? canonical.replaceAll('_', ' ') : translated;
  }

  final eventType = event['tipo_evento']?.toString();
  final previous = stateLabel(event['estado_anterior']);
  final next = stateLabel(event['estado_nuevo']);

  if (eventType == 'estado_actualizado' &&
      previous.isNotEmpty &&
      next.isNotEmpty) {
    return context
        .tr('event.status_changed')
        .replaceAll('{previous}', previous)
        .replaceAll('{next}', next);
  }
  if (eventType == 'postulacion_creada' && next.isNotEmpty) {
    return context.tr('event.application_created').replaceAll('{state}', next);
  }

  return prettyEventText(context, event['descripcion']?.toString() ?? '');
}

String relativeDateT(BuildContext context, String? raw) {
  if (raw == null) return '';
  final date = DateTime.tryParse(raw);
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return context.tr('time.now');
  if (diff.inHours < 1) {
    return context
        .tr('time.minutes_ago')
        .replaceAll('{count}', '${diff.inMinutes}');
  }
  if (diff.inDays < 1) {
    return context
        .tr('time.hours_ago')
        .replaceAll('{count}', '${diff.inHours}');
  }
  if (diff.inDays == 1) return context.tr('time.yesterday');
  return context.tr('time.days_ago').replaceAll('{count}', '${diff.inDays}');
}
