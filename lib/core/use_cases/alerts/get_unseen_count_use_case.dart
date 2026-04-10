import '../../failure.dart';
import '../../ports/alert_repository.dart';

class GetUnseenCountUseCase {
  final AlertRepository _alertRepository;

  GetUnseenCountUseCase(this._alertRepository);

  Future<Result<int>> call() {
    return _alertRepository.getUnseenCount();
  }
}
