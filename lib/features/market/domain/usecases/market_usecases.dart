import '../entities/market_price.dart';
import '../repositories/market_repository.dart';

class GetMarketData {
  const GetMarketData(this._repository);

  final MarketRepository _repository;

  Future<Map<String, MarketPrice>> call(List<String> symbols, String currency) =>
      _repository.getPrices(symbols, currency);
}

class GetTokenPrice {
  const GetTokenPrice(this._repository);

  final MarketRepository _repository;

  Future<MarketPrice?> call(String symbol, String currency) async =>
      (await _repository.getPrices([symbol], currency))[symbol.toUpperCase()];
}
