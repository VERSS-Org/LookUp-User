import 'package:url_launcher/url_launcher.dart';

/// Enlaces entre los portales de LookUp.
///
/// Desarrollo usa el puerto local conocido. Staging y produccion deben
/// inyectar `LOOKUP_RECRUITER_PORTAL_URL` para no fijar un dominio en codigo.
abstract final class PortalLinks {
  static const String _recruiterPortalUrl = String.fromEnvironment(
    'LOOKUP_RECRUITER_PORTAL_URL',
    defaultValue: 'http://localhost:8085',
  );

  static Uri? get recruiterPortalUri {
    final value = _recruiterPortalUrl.trim();
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAuthority) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }

  static Future<bool> openRecruiterPortal() async {
    final uri = recruiterPortalUri;
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
