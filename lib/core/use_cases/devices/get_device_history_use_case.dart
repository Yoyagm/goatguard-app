import '../../entities/device_snapshot.dart';
import '../../failure.dart';
import '../../ports/device_repository.dart';

class GetDeviceHistoryUseCase {
  final DeviceRepository _deviceRepository;

  GetDeviceHistoryUseCase(this._deviceRepository);

  Future<Result<List<DeviceSnapshotEntity>>> call(
    int deviceId, {
    int hours = 4,
  }) {
    return _deviceRepository.getDeviceHistory(deviceId, hours: hours);
  }
}
