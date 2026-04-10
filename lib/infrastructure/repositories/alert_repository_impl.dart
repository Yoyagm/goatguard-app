import '../../core/entities/alert.dart';
import '../../core/failure.dart';
import '../../core/ports/alert_repository.dart';
import '../../services/api_service.dart';
import '../dtos/alert_dto.dart';
import '../mappers/alert_mapper.dart';

class AlertRepositoryImpl implements AlertRepository {
  final ApiService _api;

  AlertRepositoryImpl(this._api);

  @override
  Future<Result<List<NetworkAlertEntity>>> getAlerts({
    String? severity,
    bool? seen,
    int limit = 50,
  }) async {
    try {
      final raw = await _api.getAlerts(
        severity: severity,
        seen: seen,
        limit: limit,
      );
      final entities = raw.map((j) {
        final dto = AlertDto.fromJson(j as Map<String, dynamic>);
        return AlertMapper.toEntity(dto);
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
  Future<Result<int>> getUnseenCount() async {
    try {
      final data = await _api.getAlertCount();
      final count = data['unseen_count'] as int? ?? 0;
      return Success(count);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }

  @override
  Future<Result<void>> markAsSeen(int alertId) async {
    try {
      await _api.markAlertSeen(alertId);
      return const Success(null);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return Err(UnauthorizedFailure());
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Err(NetworkFailure());
    }
  }
}
