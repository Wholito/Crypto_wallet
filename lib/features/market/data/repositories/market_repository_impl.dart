import '../../domain/entities/market_price.dart';
import '../../domain/repositories/market_repository.dart';
import '../datasources/market_remote_datasource.dart';

class MarketRepositoryImpl implements MarketRepository {
  const MarketRepositoryImpl(this._remote);

  final MarketRemoteDataSource _remote;

  @override
  Future<Map<String, MarketPrice>> getPrices(
    List<String> symbols,
    String currency,
  ) async {
    final raw = await _remote.fetch(symbols, currency);
    return {
      for (final entry in raw.entries)
        if (entry.value['price'] != null)
          entry.key: MarketPrice(
            symbol: entry.key,
            price: (entry.value['price'] as num).toDouble(),
            change24h: (entry.value['change24h'] as num?)?.toDouble(),
          ),
    };
  }
}
