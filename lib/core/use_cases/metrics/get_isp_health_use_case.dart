import '../../entities/isp_health.dart';
import '../../failure.dart';
import '../../ports/network_repository.dart';

class GetIspHealthUseCase {
  final NetworkRepository _networkRepository;

  GetIspHealthUseCase(this._networkRepository);

  Future<Result<IspHealthDetailEntity>> call() {
    return _networkRepository.getIspHealth();
  }
}
