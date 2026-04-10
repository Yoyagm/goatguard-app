import '../../core/entities/agent.dart';
import '../../core/failure.dart';
import '../../core/ports/agent_repository.dart';
import '../../services/api_service.dart';
import '../dtos/agent_dto.dart';
import '../mappers/agent_mapper.dart';

class AgentRepositoryImpl implements AgentRepository {
  final ApiService _api;

  AgentRepositoryImpl(this._api);

  @override
  Future<Result<List<AgentEntity>>> getAgents({String? status}) async {
    try {
      final raw = await _api.getAgents(status: status);
      final entities = raw.map((j) {
        final dto = AgentDto.fromJson(j as Map<String, dynamic>);
        return AgentMapper.toEntity(dto);
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
