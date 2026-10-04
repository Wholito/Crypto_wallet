import '../entities/market_price.dart';

abstract class MarketRepository {
  Future<Map<String, MarketPrice>> getPrices(List<String> symbols, String currency);
}
