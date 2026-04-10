import '../entities/real_time_event.dart';

abstract class RealTimePort {
  Stream<RealTimeEvent> get events;
  void connect(String url);
  void disconnect();
  bool get isConnected;
  void dispose();
}
