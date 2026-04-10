import '../../entities/device.dart';
import '../../failure.dart';
import '../../ports/device_repository.dart';

class GetDevicesUseCase {
  final DeviceRepository _deviceRepository;

  GetDevicesUseCase(this._deviceRepository);

  Future<Result<List<DeviceEntity>>> call() {
    return _deviceRepository.getDevices();
  }
}
