import '../../core/entities/dashboard_summary.dart';
import '../../core/entities/isp_health.dart';
import '../../core/entities/network_snapshot.dart';
import '../../core/entities/top_consumer.dart';
import '../../core/entities/top_talker_snapshot.dart';
import '../../core/entities/traffic_distribution.dart';
import '../../core/failure.dart';
import '../../core/ports/network_repository.dart';
import '../../services/api_service.dart';
import '../dtos/dashboard_summary_dto.dart';
import '../dtos/isp_health_dto.dart';
import '../dtos/network_snapshot_dto.dart';
import '../dtos/top_consumer_dto.dart';
import '../dtos/top_talker_snapshot_dto.dart';
import '../dtos/traffic_distribution_dto.dart';
import '../mappers/dashboard_summary_mapper.dart';
import '../mappers/isp_health_mapper.dart';
import '../mappers/network_snapshot_mapper.dart';
import '../mappers/top_consumer_mapper.dart';
import '../mappers/top_talker_snapshot_mapper.dart';
import '../mappers/traffic_distribution_mapper.dart';

class NetworkRepositoryImpl implements NetworkRepository {
  final ApiService _api;

  NetworkRepositoryImpl(this._api);

  @override
  Future<Result<Map<String, dynamic>>> getRawNetworkMetrics() async {
    try {
      final data = await _api.getNetworkMetrics();
      return Success(data);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<List<TopConsumerEntity>>> getTopTalkers() async {
    try {
      final raw = await _api.getTopTalkers();
      final entities = raw.map((j) {
        final dto = TopConsumerDto.fromJson(j as Map<String, dynamic>);
        return TopConsumerMapper.toEntity(dto);
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
  Future<Result<List<NetworkSnapshotEntity>>> getNetworkHistory({
    int hours = 4,
  }) async {
    try {
      final raw = await _api.getNetworkHistory(hours: hours);
      final entities = raw.map((j) {
        final dto = NetworkSnapshotDto.fromJson(j as Map<String, dynamic>);
        return NetworkSnapshotMapper.toEntity(dto);
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
  Future<Result<IspHealthDetailEntity>> getIspHealth() async {
    try {
      final raw = await _api.getIspHealth();
      final dto = IspHealthDto.fromJson(raw);
      return Success(IspHealthMapper.toEntity(dto));
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<TrafficDistributionEntity>> getTrafficDistribution() async {
    try {
      final raw = await _api.getTrafficDistribution();
      final dto = TrafficDistributionDto.fromJson(raw);
      return Success(TrafficDistributionMapper.toEntity(dto));
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<List<TopTalkerSnapshotEntity>>> getTopTalkersHistory({
    int hours = 4,
  }) async {
    try {
      final raw = await _api.getTopTalkersHistory(hours: hours);
      final entities = raw.map((j) {
        final dto = TopTalkerSnapshotDto.fromJson(j as Map<String, dynamic>);
        return TopTalkerSnapshotMapper.toEntity(dto);
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
  Future<Result<DashboardSummaryEntity>> getDashboardSummary() async {
    try {
      final raw = await _api.getDashboardSummary();
      final dto = DashboardSummaryDto.fromJson(raw);
      return Success(DashboardSummaryMapper.toEntity(dto));
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }
}
