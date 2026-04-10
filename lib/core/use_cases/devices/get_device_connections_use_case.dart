import '../../entities/device_connection.dart';
import '../../failure.dart';
import '../../ports/device_repository.dart';

class GetDeviceConnectionsUseCase {
  final DeviceRepository _deviceRepository;

  GetDeviceConnectionsUseCase(this._deviceRepository);

  Future<Result<List<DeviceConnectionEntity>>> call(int deviceId) {
    return _deviceRepository.getDeviceConnections(deviceId);
  }
}
