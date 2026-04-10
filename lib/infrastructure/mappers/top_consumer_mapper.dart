import '../../core/entities/top_consumer.dart';
import '../dtos/top_consumer_dto.dart';

class TopConsumerMapper {
  const TopConsumerMapper._();

  static TopConsumerEntity toEntity(TopConsumerDto dto) {
    final bytes = (dto.totalConsumption as num?)?.toDouble() ?? 0;
    return TopConsumerEntity(
      name: dto.alias ?? dto.hostname ?? dto.ip ?? 'Unknown',
      ip: dto.ip ?? '',
      consumptionMbps: bytes * 8 / 1000000, // bytes -> Mbps
    );
  }
}
