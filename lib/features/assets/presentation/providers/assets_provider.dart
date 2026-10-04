import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_providers.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../data/repositories/assets_repository_impl.dart';
import '../../domain/entities/asset.dart';
import '../../domain/repositories/assets_repository.dart';
import '../../domain/usecases/assets_usecases.dart';

final assetsRepositoryProvider = Provider<AssetsRepository>(
  (ref) => AssetsRepositoryImpl(
    ref.watch(blockchainDataSourceProvider),
    ref.watch(cacheBoxProvider),
    ref.watch(currentNetworkProvider),
  ),
);

final getBalanceProvider =
    Provider((ref) => GetBalance(ref.watch(assetsRepositoryProvider)));
final getAssetsProvider =
    Provider((ref) => GetAssets(ref.watch(assetsRepositoryProvider)));

class AssetsNotifier extends AsyncNotifier<List<Asset>> {
  @override
  Future<List<Asset>> build() async {
    final address = ref.watch(walletAddressProvider);
    if (address == null) return const [];
    final getAssets = ref.watch(getAssetsProvider);
    final cached = getAssets.cached(address);
    if (cached != null) {
      Future.microtask(() {
        if (ref.mounted) refresh();
      });
      return cached;
    }
    return getAssets(address);
  }

  Future<void> refresh() async {
    final address = ref.read(walletAddressProvider);
    final chainId = ref.read(currentNetworkProvider).chainId;
    if (address == null) return;
    try {
      final assets = await ref.read(getAssetsProvider)(address);
      if (!ref.mounted) return;
      if (ref.read(walletAddressProvider) != address ||
          ref.read(currentNetworkProvider).chainId != chainId) {
        return;
      }
      state = AsyncData(assets);
    } catch (error, stack) {
      if (ref.mounted) {
        state = AsyncError<List<Asset>>(error, stack);
      }
    }
  }
}

final assetsProvider =
    AsyncNotifierProvider<AssetsNotifier, List<Asset>>(AssetsNotifier.new);
