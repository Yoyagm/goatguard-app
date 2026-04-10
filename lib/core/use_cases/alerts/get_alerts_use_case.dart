import '../../entities/alert.dart';
import '../../failure.dart';
import '../../ports/alert_repository.dart';

class GetAlertsUseCase {
  final AlertRepository _alertRepository;

  GetAlertsUseCase(this._alertRepository);

  Future<Result<List<NetworkAlertEntity>>> call({
    String? severity,
    bool? seen,
    int limit = 50,
  }) {
    return _alertRepository.getAlerts(
      severity: severity,
      seen: seen,
      limit: limit,
    );
  }
}
