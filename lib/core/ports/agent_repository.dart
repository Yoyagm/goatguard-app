import '../entities/agent.dart';
import '../failure.dart';

abstract class AgentRepository {
  Future<Result<List<AgentEntity>>> getAgents({String? status});
}
