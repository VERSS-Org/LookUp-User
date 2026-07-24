import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/services/locale_controller.dart';

/// Colores de marca LookUp (constantes entre modos).
const Color kBrandBlue = Color(0xFF28348A);
const Color kBrandBlueBright = Color(0xFF2C3CA6);
const Color kSkyBlue = Color(0xFF22A9E8);
const Color kInkNavy = Color(0xFF11182D);
const String kLookUpFontFamily = 'Manrope';
const String kLookUpBodyFontFamily = 'Manrope';
const String kLookUpHeadingFontFamily = 'Sora';
const List<String> kLookUpFontFallback = ['Arial', 'sans-serif'];
const LinearGradient kLookUpBrandGradient = LinearGradient(
  colors: [kBrandBlue, kSkyBlue],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

TextStyle _lookUpTextStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
  double? letterSpacing,
  String fontFamily = kLookUpBodyFontFamily,
}) => TextStyle(
  fontFamily: fontFamily,
  fontFamilyFallback: kLookUpFontFallback,
  color: color,
  fontSize: fontSize,
  fontWeight: fontWeight,
  height: height,
  letterSpacing: letterSpacing,
);

/// Transición compartida para que la navegación se sienta continua en web
/// y móvil sin animaciones llamativas.
class LookUpPageTransitionsBuilder extends PageTransitionsBuilder {
  const LookUpPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.88, end: 1).animate(curvedAnimation),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.012, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}

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
    background: Color(0xFFF4F6FB),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEDF1F9),
    border: Color(0xFFDCE3F0),
    ink: kInkNavy,
    inkMuted: Color(0xFF53607A),
    inkFaint: Color(0xFF8792AA),
    brand: kBrandBlueBright,
    accent: Color(0xFF0D8ECF),
    success: Color(0xFF14945E),
    warning: Color(0xFFB36B0D),
    danger: Color(0xFFD14343),
    chipAlpha: 0.11,
  );

  // Modo oscuro sobre grises neutros (no azulados): descansa mejor la vista
  // y deja que el azul de marca destaque solo donde importa.
  static const dark = LookUpColors(
    background: Color(0xFF151923),
    surface: Color(0xFF1D2330),
    surfaceAlt: Color(0xFF272E3E),
    border: Color(0xFF354055),
    ink: Color(0xFFF5F7FC),
    inkMuted: Color(0xFFB4BED2),
    inkFaint: Color(0xFF7F8AA1),
    brand: Color(0xFFAAB5FF),
    accent: Color(0xFF59C7F4),
    success: Color(0xFF63C996),
    warning: Color(0xFFE5AD61),
    danger: Color(0xFFF08383),
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
  final primary = palette.brand;

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: kLookUpBodyFontFamily,
    fontFamilyFallback: kLookUpFontFallback,
    visualDensity: VisualDensity.standard,
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

  final textTheme = base.textTheme
      .apply(
        fontFamily: kLookUpBodyFontFamily,
        fontFamilyFallback: kLookUpFontFallback,
      )
      .apply(bodyColor: palette.ink, displayColor: palette.ink)
      .copyWith(
        displayLarge: _lookUpTextStyle(
          fontFamily: kLookUpHeadingFontFamily,
          fontSize: 38,
          fontWeight: FontWeight.w700,
          color: palette.ink,
          height: 1.12,
          letterSpacing: -1,
        ),
        displayMedium: _lookUpTextStyle(
          fontFamily: kLookUpHeadingFontFamily,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: palette.ink,
          height: 1.15,
          letterSpacing: -0.7,
        ),
        headlineLarge: _lookUpTextStyle(
          fontFamily: kLookUpHeadingFontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: palette.ink,
          height: 1.18,
          letterSpacing: -0.45,
        ),
        headlineMedium: _lookUpTextStyle(
          fontFamily: kLookUpHeadingFontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: palette.ink,
          height: 1.2,
          letterSpacing: -0.3,
        ),
        headlineSmall: _lookUpTextStyle(
          fontFamily: kLookUpHeadingFontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: palette.ink,
          height: 1.22,
          letterSpacing: -0.2,
        ),
        titleLarge: _lookUpTextStyle(
          fontFamily: kLookUpHeadingFontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
          color: palette.ink,
          height: 1.25,
        ),
        titleMedium: _lookUpTextStyle(
          fontFamily: kLookUpHeadingFontFamily,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: palette.ink,
          height: 1.3,
        ),
        titleSmall: _lookUpTextStyle(
          fontFamily: kLookUpHeadingFontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: palette.ink,
          height: 1.3,
        ),
        bodyLarge: _lookUpTextStyle(
          fontSize: 15,
          height: 1.5,
          color: palette.ink,
        ),
        bodyMedium: _lookUpTextStyle(
          fontSize: 14,
          height: 1.48,
          color: palette.ink,
        ),
        bodySmall: _lookUpTextStyle(
          fontSize: 12.5,
          height: 1.42,
          color: palette.inkMuted,
        ),
        labelLarge: _lookUpTextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: _lookUpTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: _lookUpTextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: palette.inkMuted,
        ),
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
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: LookUpPageTransitionsBuilder(),
        TargetPlatform.iOS: LookUpPageTransitionsBuilder(),
        TargetPlatform.macOS: LookUpPageTransitionsBuilder(),
        TargetPlatform.windows: LookUpPageTransitionsBuilder(),
        TargetPlatform.linux: LookUpPageTransitionsBuilder(),
        TargetPlatform.fuchsia: LookUpPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.surface,
      foregroundColor: palette.ink,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 60,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: _lookUpTextStyle(
        fontFamily: kLookUpHeadingFontFamily,
        color: palette.ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      shape: Border(bottom: BorderSide(color: palette.border)),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: palette.inkMuted,
        minimumSize: const Size(42, 42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: palette.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: palette.surfaceAlt,
        disabledForegroundColor: palette.inkFaint,
        minimumSize: const Size(64, 44),
        elevation: 0,
        textStyle: _lookUpTextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: _lookUpTextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.brand,
        minimumSize: const Size(64, 44),
        side: BorderSide(color: palette.border),
        textStyle: _lookUpTextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.brand,
        textStyle: _lookUpTextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      hintStyle: _lookUpTextStyle(color: palette.inkFaint),
      labelStyle: _lookUpTextStyle(color: palette.inkMuted),
      helperStyle: _lookUpTextStyle(color: palette.inkFaint, fontSize: 12),
      floatingLabelStyle: _lookUpTextStyle(
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
      height: 64,
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: primary.withValues(alpha: isDark ? 0.28 : 0.12),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => _lookUpTextStyle(
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
      contentTextStyle: _lookUpTextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.border),
      ),
      titleTextStyle: _lookUpTextStyle(
        fontFamily: kLookUpHeadingFontFamily,
        color: palette.ink,
        fontSize: 18,
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
      labelStyle: _lookUpTextStyle(
        color: palette.ink,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      shape: const StadiumBorder(),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: primary.withValues(alpha: isDark ? 0.3 : 0.1),
        selectedForegroundColor: palette.brand,
        foregroundColor: palette.inkMuted,
        side: BorderSide(color: palette.border),
        textStyle: _lookUpTextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: const StadiumBorder(),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: palette.border),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: palette.brand,
      unselectedLabelColor: palette.inkMuted,
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: palette.brand.withValues(alpha: isDark ? 0.24 : 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      labelStyle: _lookUpTextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
      unselectedLabelStyle: _lookUpTextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStatePropertyAll(palette.surfaceAlt),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      hintStyle: WidgetStatePropertyAll(
        _lookUpTextStyle(color: palette.inkFaint, fontSize: 12.5),
      ),
      textStyle: WidgetStatePropertyAll(
        _lookUpTextStyle(color: palette.ink, fontSize: 12.5),
      ),
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: palette.danger,
      textColor: Colors.white,
      textStyle: _lookUpTextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : palette.inkFaint,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.brand
            : palette.surfaceAlt,
      ),
      trackOutlineColor: WidgetStatePropertyAll(palette.border),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(
        palette.inkFaint.withValues(alpha: 0.48),
      ),
      radius: const Radius.circular(8),
      thickness: const WidgetStatePropertyAll(4),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: isDark ? palette.surfaceAlt : const Color(0xFF232B3E),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: _lookUpTextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}
