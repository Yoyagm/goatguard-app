import '../entities/device.dart';
import '../entities/device_comparison.dart';
import '../entities/device_connection.dart';
import '../entities/device_snapshot.dart';
import '../failure.dart';

abstract class DeviceRepository {
  Future<Result<List<DeviceEntity>>> getDevices();
  Future<Result<DeviceEntity>> getDevice(int id);
  Future<Result<void>> updateAlias(int deviceId, String alias);
  Future<Result<List<DeviceSnapshotEntity>>> getDeviceHistory(
    int deviceId, {
    int hours = 4,
  });
  Future<Result<List<DeviceConnectionEntity>>> getDeviceConnections(
    int deviceId,
  );
  Future<Result<List<DeviceComparisonEntity>>> getDeviceComparison({
    String metric = 'bandwidth_in',
  });
}
