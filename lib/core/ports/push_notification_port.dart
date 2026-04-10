abstract class PushNotificationPort {
  Future<void> initialize();
  Future<void> registerToken();
  Future<void> unregisterToken();
  set onForegroundAlert(void Function()? callback);
  set onNotificationTap(void Function()? callback);
  void dispose();
}
