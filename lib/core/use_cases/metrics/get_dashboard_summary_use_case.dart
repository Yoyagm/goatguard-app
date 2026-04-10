import '../../entities/dashboard_summary.dart';
import '../../failure.dart';
import '../../ports/network_repository.dart';

class GetDashboardSummaryUseCase {
  final NetworkRepository _networkRepository;

  GetDashboardSummaryUseCase(this._networkRepository);

  Future<Result<DashboardSummaryEntity>> call() {
    return _networkRepository.getDashboardSummary();
  }
}
