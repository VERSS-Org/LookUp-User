import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lookup_user/src/screens/session_gate.dart';
import 'package:lookup_user/src/services/auth_service.dart';
import 'package:lookup_user/src/services/data_service.dart';
import 'package:lookup_user/src/services/locale_controller.dart';
import 'package:lookup_user/src/services/theme_controller.dart';
import 'package:lookup_user/src/theme.dart';

// La app esta organizada en modulos bajo lib/src/. Se re-exporta la API
// principal para mantener estables los imports existentes (p. ej. tests).
export 'package:lookup_user/src/screens/app_shell.dart';
export 'package:lookup_user/src/screens/auth_screen.dart';
export 'package:lookup_user/src/screens/session_gate.dart';
export 'package:lookup_user/src/services/api_service.dart';
export 'package:lookup_user/src/services/auth_service.dart';
export 'package:lookup_user/src/services/data_service.dart';
export 'package:lookup_user/src/services/locale_controller.dart';
export 'package:lookup_user/src/services/theme_controller.dart';
export 'package:lookup_user/src/theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => LocaleController()),
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
    final themeController = context.watch<ThemeController>();
    final language = context.watch<LocaleController>().language;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LookUp',
      locale: Locale(language),
      theme: buildLookUpTheme(Brightness.light),
      darkTheme: buildLookUpTheme(Brightness.dark),
      themeMode: themeController.mode,
      // Los widgets traducidos observan LocaleController directamente; no se
      // reemplaza SessionGate para conservar la sesión y la navegación activa.
      home: const SessionGate(),
    );
  }
}
