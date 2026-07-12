# LookUp Postulantes

Aplicación Flutter para postulantes de LookUp.

## Funcionalidad

- Registro e inicio de sesión de postulantes con validación de contraseña fuerte.
- Exploración de vacantes abiertas con búsqueda y detalle completo.
- Postulación a vacantes.
- Historial de postulaciones con hitos, estados y feedback.
- Mensajes con las empresas por postulación.
- Progreso personal y logros.
- Perfil editable, foto de perfil y cambio de contraseña.

El código está organizado en módulos bajo `lib/src/` (services, screens,
widgets, theme y utils); `lib/main.dart` re-exporta la API principal.

## Configuración

La app apunta a `http://localhost:8000` por defecto. Para usar otro backend:

```bash
flutter run --dart-define=LOOKUP_API_BASE_URL=http://localhost:8000
```

En Android Emulator usa:

```bash
flutter run --dart-define=LOOKUP_API_BASE_URL=http://10.0.2.2:8000
```

En un teléfono físico usa la IP LAN de la PC, por ejemplo `http://192.168.1.20:8000`.
El valor puede incluir o no `/api`; la app lo normaliza internamente.

El enlace al portal de empresas mostrado en el acceso usa
`http://localhost:8085` durante el desarrollo. Para otro entorno, define su URL
HTTP o HTTPS al ejecutar o compilar la aplicación:

```bash
flutter run --dart-define=LOOKUP_RECRUITER_PORTAL_URL=https://empresas.ejemplo.com
```

## Verificación

```bash
flutter pub get
flutter analyze
flutter test
flutter build web
```
