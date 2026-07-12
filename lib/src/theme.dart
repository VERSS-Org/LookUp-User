import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/services/locale_controller.dart';

/// Colores de marca LookUp (constantes entre modos).
const Color kBrandBlue = Color(0xFF28348A);
const Color kBrandBlueBright = Color(0xFF4053C8);
const Color kSkyBlue = Color(0xFF22A9E8);

/// Tokens de color dependientes del modo (claro/oscuro).
///
/// Se accede con `context.colors`. Los widgets no deben usar colores fijos de
/// tinta/superficie: siempre a traves de esta extension para que el modo
/// oscuro funcione en toda la app.
class LookUpColors extends ThemeExtension<LookUpColors> {
  const LookUpColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.brand,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.chipAlpha,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;

  /// Azul de marca legible sobre `surface` en el modo actual.
  final Color brand;

  /// Cian de acento legible sobre `surface` en el modo actual.
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;

  /// Opacidad base para fondos de chips/insignias.
  final double chipAlpha;

  static const light = LookUpColors(
    background: Color(0xFFF6F7FA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0F2F7),
    border: Color(0xFFE3E7EF),
    ink: Color(0xFF1A2233),
    inkMuted: Color(0xFF5C6577),
    inkFaint: Color(0xFF8B93A7),
    brand: kBrandBlue,
    accent: Color(0xFF0E7FB6),
    success: Color(0xFF1E7F4F),
    warning: Color(0xFFA36716),
    danger: Color(0xFFC03D3D),
    chipAlpha: 0.10,
  );

  // Modo oscuro sobre grises neutros (no azulados): descansa mejor la vista
  // y deja que el azul de marca destaque solo donde importa.
  static const dark = LookUpColors(
    background: Color(0xFF141416),
    surface: Color(0xFF1C1C1F),
    surfaceAlt: Color(0xFF27272B),
    border: Color(0xFF323237),
    ink: Color(0xFFEDEDEF),
    inkMuted: Color(0xFFA6A7AD),
    inkFaint: Color(0xFF77787F),
    brand: Color(0xFFA3B0FF),
    accent: Color(0xFF57BDF0),
    success: Color(0xFF5BC48D),
    warning: Color(0xFFE0A65A),
    danger: Color(0xFFEF7B7B),
    chipAlpha: 0.16,
  );

  @override
  LookUpColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    Color? brand,
    Color? accent,
    Color? success,
    Color? warning,
    Color? danger,
    double? chipAlpha,
  }) {
    return LookUpColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      brand: brand ?? this.brand,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      chipAlpha: chipAlpha ?? this.chipAlpha,
    );
  }

  @override
  LookUpColors lerp(ThemeExtension<LookUpColors>? other, double t) {
    if (other is! LookUpColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return LookUpColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceAlt: mix(surfaceAlt, other.surfaceAlt),
      border: mix(border, other.border),
      ink: mix(ink, other.ink),
      inkMuted: mix(inkMuted, other.inkMuted),
      inkFaint: mix(inkFaint, other.inkFaint),
      brand: mix(brand, other.brand),
      accent: mix(accent, other.accent),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      danger: mix(danger, other.danger),
      chipAlpha: chipAlpha + (other.chipAlpha - chipAlpha) * t,
    );
  }
}

extension LookUpColorsX on BuildContext {
  LookUpColors get colors => Theme.of(this).extension<LookUpColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Normaliza los estados a su forma canonica (el backend acepta ambas apps
/// deben mostrar exactamente el mismo conjunto de estados).
String canonicalEstado(String estado) =>
    switch (estado.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_')) {
      'rechazo' => 'rechazado',
      'oferta' => 'aceptado',
      'en_progreso' => 'en_revision',
      final normalizado => normalizado,
    };

/// Color, etiqueta traducida e icono de cada estado del proceso.
({Color color, String label, IconData icon}) estadoStyle(
  BuildContext context,
  String estado,
) {
  final c = context.colors;
  final canonico = canonicalEstado(estado);

  String label;
  try {
    label = Provider.of<LocaleController>(
      context,
      listen: false,
    ).t('estado.$canonico');
  } catch (_) {
    label = canonico;
  }
  if (label == 'estado.$canonico') label = canonico;

  return switch (canonico) {
    'pendiente' => (
      color: c.inkMuted,
      label: label,
      icon: Icons.schedule_outlined,
    ),
    'en_revision' => (
      color: c.warning,
      label: label,
      icon: Icons.visibility_outlined,
    ),
    'entrevista' => (
      color: c.accent,
      label: label,
      icon: Icons.event_available_outlined,
    ),
    'aceptado' => (
      color: c.success,
      label: label,
      icon: Icons.thumb_up_alt_outlined,
    ),
    'rechazado' => (color: c.danger, label: label, icon: Icons.cancel_outlined),
    'abierto' => (
      color: c.success,
      label: label,
      icon: Icons.radio_button_checked,
    ),
    'cerrado' => (color: c.inkFaint, label: label, icon: Icons.lock_outline),
    _ => (color: c.brand, label: label, icon: Icons.circle_outlined),
  };
}

ThemeData buildLookUpTheme(Brightness brightness) {
  final palette = brightness == Brightness.dark
      ? LookUpColors.dark
      : LookUpColors.light;
  final isDark = brightness == Brightness.dark;
  final primary = isDark ? kBrandBlueBright : kBrandBlue;

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kBrandBlue,
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: kSkyBlue,
      surface: palette.surface,
      onSurface: palette.ink,
      error: palette.danger,
      outline: palette.border,
    ),
    scaffoldBackgroundColor: palette.background,
  );

  final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme)
      .apply(bodyColor: palette.ink, displayColor: palette.ink)
      .copyWith(
        headlineSmall: GoogleFonts.poppins(
          fontSize: 23,
          fontWeight: FontWeight.w600,
          color: palette.ink,
          height: 1.25,
        ),
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: palette.ink,
        ),
        titleMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: palette.ink,
        ),
        bodyMedium: GoogleFonts.poppins(height: 1.45, color: palette.ink),
        bodySmall: GoogleFonts.poppins(color: palette.inkMuted),
        labelLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      );

  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );

  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    extensions: [palette],
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.poppins(
        color: palette.ink,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      shape: Border(bottom: BorderSide(color: palette.border)),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: palette.surfaceAlt,
        disabledForegroundColor: palette.inkFaint,
        minimumSize: const Size(64, 48),
        elevation: 0,
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.brand,
        minimumSize: const Size(64, 46),
        side: BorderSide(color: palette.border, width: 1.2),
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.brand,
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: GoogleFonts.poppins(color: palette.inkFaint),
      labelStyle: GoogleFonts.poppins(color: palette.inkMuted),
      helperStyle: GoogleFonts.poppins(color: palette.inkFaint, fontSize: 12),
      floatingLabelStyle: GoogleFonts.poppins(
        color: palette.brand,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: palette.inkFaint,
      suffixIconColor: palette.inkFaint,
      border: inputBorder(palette.border),
      enabledBorder: inputBorder(palette.border),
      focusedBorder: inputBorder(palette.brand, 1.5),
      errorBorder: inputBorder(palette.danger),
      focusedErrorBorder: inputBorder(palette.danger, 1.5),
    ),
    dividerTheme: DividerThemeData(
      color: palette.border,
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 66,
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: primary.withValues(alpha: isDark ? 0.28 : 0.12),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? palette.brand
              : palette.inkMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? palette.brand
              : palette.inkMuted,
          size: 23,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? palette.surfaceAlt : const Color(0xFF232B3E),
      contentTextStyle: GoogleFonts.poppins(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.border),
      ),
      titleTextStyle: GoogleFonts.poppins(
        color: palette.ink,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.brand),
    listTileTheme: ListTileThemeData(iconColor: palette.brand),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: palette.surfaceAlt,
      side: BorderSide(color: palette.border),
      labelStyle: GoogleFonts.poppins(color: palette.ink, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: primary.withValues(alpha: isDark ? 0.3 : 0.1),
        selectedForegroundColor: palette.brand,
        foregroundColor: palette.inkMuted,
        side: BorderSide(color: palette.border),
        textStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: isDark ? palette.surfaceAlt : const Color(0xFF232B3E),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
    ),
  );
}
