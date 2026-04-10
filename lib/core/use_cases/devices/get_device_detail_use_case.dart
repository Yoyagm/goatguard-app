import '../../entities/device.dart';
import '../../failure.dart';
import '../../ports/device_repository.dart';

class GetDeviceDetailUseCase {
  final DeviceRepository _deviceRepository;

  GetDeviceDetailUseCase(this._deviceRepository);

  Future<Result<DeviceEntity>> call(int id) {
    return _deviceRepository.getDevice(id);
  }
}
