import '../entities/alert.dart';
import '../failure.dart';

abstract class AlertRepository {
  Future<Result<List<NetworkAlertEntity>>> getAlerts({
    String? severity,
    bool? seen,
    int limit = 50,
  });
  Future<Result<int>> getUnseenCount();
  Future<Result<void>> markAsSeen(int alertId);
}
