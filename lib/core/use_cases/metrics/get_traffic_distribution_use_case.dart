import '../../entities/traffic_distribution.dart';
import '../../failure.dart';
import '../../ports/network_repository.dart';

class GetTrafficDistributionUseCase {
  final NetworkRepository _networkRepository;

  GetTrafficDistributionUseCase(this._networkRepository);

  Future<Result<TrafficDistributionEntity>> call() {
    return _networkRepository.getTrafficDistribution();
  }
}
