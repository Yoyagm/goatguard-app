import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Servicio WebSocket con reconexión exponencial [RF-17]
///
/// El server hace broadcast cada 5s con:
/// { type: "state_update", network: {...}, devices: [...], unseen_alerts: N }
/// JWT pasa como query param: `ws://host/ws?token=JWT`
class WebSocketService {
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  String? _url;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelaySec = 30;
  bool _disposed = false;

  /// Stream de state_update parseados
  Stream<Map<String, dynamic>> get stateUpdates => _controller.stream;

  bool get isConnected => _channel != null;

  void connect(String url) {
    _url = url;
    _reconnectAttempts = 0;
    _doConnect();
  }

  Future<void> _doConnect() async {
    if (_disposed || _url == null) return;

    _channel?.sink.close();
    _channel = null;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url!));

      // Esperar a que la conexión se establezca antes de escuchar
      await _channel!.ready;

      _channel!.stream.listen(
        (raw) {
          _reconnectAttempts = 0;
          try {
            final parsed = jsonDecode(raw as String) as Map<String, dynamic>;
            _controller.add(parsed);
          } catch (_) {
            // JSON inválido — ignorar mensaje
          }
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      // Conexión fallida (server caído, red no disponible, etc.)
      _channel = null;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _channel = null;

    // Backoff exponencial: 1s, 2s, 4s, 8s... hasta 30s
    final delaySec = min(
      pow(2, _reconnectAttempts).toInt(),
      _maxReconnectDelaySec,
    );
    _reconnectAttempts++;
    _reconnectTimer = Timer(Duration(seconds: delaySec), _doConnect);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _controller.close();
  }
}
