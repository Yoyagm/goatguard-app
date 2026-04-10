import '../../entities/agent.dart';
import '../../failure.dart';
import '../../ports/agent_repository.dart';

class GetAgentsUseCase {
  final AgentRepository _agentRepository;

  GetAgentsUseCase(this._agentRepository);

  Future<Result<List<AgentEntity>>> call({String? status}) {
    return _agentRepository.getAgents(status: status);
  }
}
