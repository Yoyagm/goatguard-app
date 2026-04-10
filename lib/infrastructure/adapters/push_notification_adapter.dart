import '../../core/ports/push_notification_port.dart';
import '../../services/fcm_service.dart';

class PushNotificationAdapter implements PushNotificationPort {
  final FcmService _fcm;

  PushNotificationAdapter(this._fcm);

  @override
  Future<void> initialize() => _fcm.initialize();

  @override
  Future<void> registerToken() => _fcm.registerToken();

  @override
  Future<void> unregisterToken() => _fcm.unregisterToken();

  @override
  set onForegroundAlert(void Function()? callback) =>
      _fcm.onForegroundAlert = callback;

  @override
  set onNotificationTap(void Function()? callback) =>
      _fcm.onNotificationTap = callback;

  @override
  void dispose() => _fcm.dispose();
}
