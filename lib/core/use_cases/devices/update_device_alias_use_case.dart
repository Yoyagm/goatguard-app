import '../../failure.dart';
import '../../ports/device_repository.dart';

class UpdateDeviceAliasUseCase {
  final DeviceRepository _deviceRepository;

  UpdateDeviceAliasUseCase(this._deviceRepository);

  Future<Result<void>> call(int deviceId, String alias) {
    return _deviceRepository.updateAlias(deviceId, alias);
  }
}
