/// Configuración de entorno para conectar con el backend.
/// En Android emulator, localhost del host se mapea a 10.0.2.2.
class Env {
  Env._();

  // Cambiar a la URL del Cloudflare Tunnel en producción
  // Android emulator: http://10.0.2.2:8000
  // Chrome/macOS/dispositivo local: http://localhost:8000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  // Para desarrollo en dispositivo físico en la misma LAN:
  // static const String apiBaseUrl = 'http://192.168.59.X:8000';
}
