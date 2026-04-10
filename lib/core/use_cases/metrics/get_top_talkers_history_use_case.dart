import '../../entities/top_talker_snapshot.dart';
import '../../failure.dart';
import '../../ports/network_repository.dart';

class GetTopTalkersHistoryUseCase {
  final NetworkRepository _networkRepository;

  GetTopTalkersHistoryUseCase(this._networkRepository);

  Future<Result<List<TopTalkerSnapshotEntity>>> call({int hours = 4}) {
    return _networkRepository.getTopTalkersHistory(hours: hours);
  }
}
