import '../../entities/device_comparison.dart';
import '../../failure.dart';
import '../../ports/device_repository.dart';

class GetDeviceComparisonUseCase {
  final DeviceRepository _deviceRepository;

  GetDeviceComparisonUseCase(this._deviceRepository);

  Future<Result<List<DeviceComparisonEntity>>> call({
    String metric = 'bandwidth_in',
  }) {
    return _deviceRepository.getDeviceComparison(metric: metric);
  }
}
