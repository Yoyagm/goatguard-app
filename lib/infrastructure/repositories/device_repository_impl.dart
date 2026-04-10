import '../../core/entities/device.dart';
import '../../core/entities/device_comparison.dart';
import '../../core/entities/device_connection.dart';
import '../../core/entities/device_snapshot.dart';
import '../../core/failure.dart';
import '../../core/ports/device_repository.dart';
import '../../services/api_service.dart';
import '../dtos/device_comparison_dto.dart';
import '../dtos/device_connection_dto.dart';
import '../dtos/device_dto.dart';
import '../dtos/device_snapshot_dto.dart';
import '../mappers/device_comparison_mapper.dart';
import '../mappers/device_connection_mapper.dart';
import '../mappers/device_mapper.dart';
import '../mappers/device_snapshot_mapper.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final ApiService _api;

  DeviceRepositoryImpl(this._api);

  @override
  Future<Result<List<DeviceEntity>>> getDevices() async {
    try {
      final raw = await _api.getDevices();
      final entities = raw.map((j) {
        final dto = DeviceDto.fromJson(j as Map<String, dynamic>);
        return DeviceMapper.toEntity(dto);
      }).toList();
      return Success(entities);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<DeviceEntity>> getDevice(int id) async {
    try {
      final raw = await _api.getDevice(id);
      final dto = DeviceDto.fromJson(raw);
      return Success(DeviceMapper.toEntity(dto));
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<void>> updateAlias(int deviceId, String alias) async {
    try {
      await _api.updateAlias(deviceId, alias);
      return const Success(null);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<List<DeviceSnapshotEntity>>> getDeviceHistory(
    int deviceId, {
    int hours = 4,
  }) async {
    try {
      final raw = await _api.getDeviceHistory(deviceId, hours: hours);
      final entities = raw.map((j) {
        final dto = DeviceSnapshotDto.fromJson(j as Map<String, dynamic>);
        return DeviceSnapshotMapper.toEntity(dto);
      }).toList();
      return Success(entities);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<List<DeviceConnectionEntity>>> getDeviceConnections(
    int deviceId,
  ) async {
    try {
      final raw = await _api.getDeviceConnections(deviceId);
      final entities = raw.map((j) {
        final dto = DeviceConnectionDto.fromJson(j as Map<String, dynamic>);
        return DeviceConnectionMapper.toEntity(dto);
      }).toList();
      return Success(entities);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<List<DeviceComparisonEntity>>> getDeviceComparison({
    String metric = 'bandwidth_in',
  }) async {
    try {
      final raw = await _api.getDeviceComparison(metric: metric);
      final entities = raw.map((j) {
        final dto = DeviceComparisonDto.fromJson(j as Map<String, dynamic>);
        return DeviceComparisonMapper.toEntity(dto);
      }).toList();
      return Success(entities);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }
}
