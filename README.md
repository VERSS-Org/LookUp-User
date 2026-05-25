# LookUp User

Aplicacion Flutter para postulantes de LookUp.

## Funcionalidad

- Registro e inicio de sesion de postulantes.
- Exploracion de ofertas abiertas.
- Postulacion a puestos.
- Historial de postulaciones con hitos y estados.
- Metricas personales.
- Perfil editable.

## Configuracion

La app usa el backend desplegado de LookUp por defecto. Para usar un backend local:

```bash
flutter run --dart-define=LOOKUP_API_BASE_URL=http://localhost:8000
```

En Android Emulator usa:

```bash
flutter run --dart-define=LOOKUP_API_BASE_URL=http://10.0.2.2:8000
```

En un telefono fisico usa la IP LAN de la PC, por ejemplo `http://192.168.1.20:8000`.
El valor puede incluir o no `/api`; la app lo normaliza internamente.

## Verificacion

```bash
flutter pub get
flutter analyze
flutter test
```
