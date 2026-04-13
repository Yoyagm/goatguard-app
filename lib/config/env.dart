import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Configuración de entorno para conectar con el backend.
class Env {
  Env._();

  static const _storageKey = 'goatguard_server_url';
  static const _storage = FlutterSecureStorage();

  /// Default: Tailscale IP del server
  static const String defaultUrl = 'http://100.93.18.78:8000';

  /// URL activa en memoria (se carga al inicio con [load])
  static String apiBaseUrl = defaultUrl;

  /// Carga la URL guardada. Llamar antes de crear ApiService.
  static Future<void> load() async {
    final saved = await _storage.read(key: _storageKey);
    if (saved != null && saved.isNotEmpty) {
      apiBaseUrl = saved;
    }
  }

  /// Guarda una nueva URL del server.
  static Future<void> setServerUrl(String url) async {
    apiBaseUrl = url;
    await _storage.write(key: _storageKey, value: url);
  }

  /// Devuelve la URL guardada (o null si usa default).
  static Future<String?> getSavedUrl() async {
    return await _storage.read(key: _storageKey);
  }
}
