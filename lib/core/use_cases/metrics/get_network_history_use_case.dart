import '../../entities/network_snapshot.dart';
import '../../failure.dart';
import '../../ports/network_repository.dart';

class GetNetworkHistoryUseCase {
  final NetworkRepository _networkRepository;

  GetNetworkHistoryUseCase(this._networkRepository);

  Future<Result<List<NetworkSnapshotEntity>>> call({int hours = 4}) {
    return _networkRepository.getNetworkHistory(hours: hours);
  }
}
