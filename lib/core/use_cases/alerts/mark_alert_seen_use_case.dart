import '../../failure.dart';
import '../../ports/alert_repository.dart';

class MarkAlertSeenUseCase {
  final AlertRepository _alertRepository;

  MarkAlertSeenUseCase(this._alertRepository);

  Future<Result<void>> call(int alertId) {
    return _alertRepository.markAsSeen(alertId);
  }
}
