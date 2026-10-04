import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/http_providers.dart';
import '../../../assets/domain/entities/asset.dart';
import '../../../assets/presentation/providers/assets_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/datasources/market_remote_datasource.dart';
import '../../data/repositories/market_repository_impl.dart';
import '../../domain/entities/market_price.dart';
import '../../domain/repositories/market_repository.dart';
import '../../domain/usecases/market_usecases.dart';

final marketRepositoryProvider = Provider<MarketRepository>(
  (ref) => MarketRepositoryImpl(
    MarketRemoteDataSource(ref.watch(httpClientProvider)),
  ),
);

final getMarketDataProvider =
    Provider((ref) => GetMarketData(ref.watch(marketRepositoryProvider)));
final getTokenPriceProvider =
    Provider((ref) => GetTokenPrice(ref.watch(marketRepositoryProvider)));

final marketPricesProvider = FutureProvider<Map<String, MarketPrice>>((ref) async {
  final settings = ref.watch(settingsProvider);
  if (settings.network.isTestnet) return const {};
  final assets = ref.watch(assetsProvider).value ?? const <Asset>[];
  if (assets.isEmpty) return const {};
  try {
    return await ref.watch(getMarketDataProvider)(
      assets.map((a) => a.symbol).toList(),
      settings.currency.toLowerCase(),
    );
  } catch (_) {
    return const {};
  }
});

final pricedAssetsProvider = Provider<AsyncValue<List<Asset>>>((ref) {
  final assets = ref.watch(assetsProvider);
  final prices = ref.watch(marketPricesProvider).value ?? const {};
  return assets.whenData(
    (list) => [
      for (final asset in list)
        prices[asset.symbol] == null
            ? asset
            : asset.copyWith(
                price: prices[asset.symbol]!.price,
                priceChange24h: prices[asset.symbol]!.change24h,
              ),
    ],
  );
});

final portfolioValueProvider = Provider<double?>((ref) {
  final assets = ref.watch(pricedAssetsProvider).value;
  if (assets == null) return null;
  final values = assets.map((a) => a.fiatValue).whereType<double>();
  return values.isEmpty ? null : values.fold<double>(0, (a, b) => a + b);
});
