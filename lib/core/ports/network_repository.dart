import '../entities/dashboard_summary.dart';
import '../entities/isp_health.dart';
import '../entities/network_snapshot.dart';
import '../entities/top_consumer.dart';
import '../entities/top_talker_snapshot.dart';
import '../entities/traffic_distribution.dart';
import '../failure.dart';

abstract class NetworkRepository {
  Future<Result<Map<String, dynamic>>> getRawNetworkMetrics();
  Future<Result<List<TopConsumerEntity>>> getTopTalkers();
  Future<Result<List<NetworkSnapshotEntity>>> getNetworkHistory({
    int hours = 4,
  });
  Future<Result<IspHealthDetailEntity>> getIspHealth();
  Future<Result<TrafficDistributionEntity>> getTrafficDistribution();
  Future<Result<List<TopTalkerSnapshotEntity>>> getTopTalkersHistory({
    int hours = 4,
  });
  Future<Result<DashboardSummaryEntity>> getDashboardSummary();
}
