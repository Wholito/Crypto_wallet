import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/storage/storage_providers.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/datasources/blockchain_datasource.dart';
import '../../data/datasources/wallet_local_datasource.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/usecases/create_wallet.dart';
import '../../domain/usecases/export_wallet.dart';
import '../../domain/usecases/get_wallet_address.dart';
import '../../domain/usecases/restore_wallet.dart';

final walletLocalDataSourceProvider = Provider<WalletLocalDataSource>(
  (ref) => WalletLocalDataSource(ref.watch(secureStorageProvider)),
);

final blockchainDataSourceProvider = Provider<BlockchainDataSource>((ref) {
  final dataSource =
      BlockchainDataSource(ref.watch(currentNetworkProvider), http.Client());
  ref.onDispose(dataSource.dispose);
  return dataSource;
});

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepositoryImpl(ref.watch(walletLocalDataSourceProvider)),
);

final generateMnemonicProvider = Provider(
  (ref) => GenerateMnemonic(ref.watch(walletRepositoryProvider)),
);
final createWalletProvider = Provider(
  (ref) => CreateWallet(ref.watch(walletRepositoryProvider)),
);
final restoreWalletProvider = Provider(
  (ref) => RestoreWallet(ref.watch(walletRepositoryProvider)),
);
final getWalletProvider = Provider(
  (ref) => GetWallet(ref.watch(walletRepositoryProvider)),
);
final getWalletAddressProvider = Provider(
  (ref) => GetWalletAddress(ref.watch(walletRepositoryProvider)),
);
final exportWalletProvider = Provider(
  (ref) => ExportWallet(ref.watch(walletRepositoryProvider)),
);
final deleteWalletProvider = Provider(
  (ref) => DeleteWallet(ref.watch(walletRepositoryProvider)),
);

class WalletNotifier extends AsyncNotifier<Wallet?> {
  @override
  Future<Wallet?> build() => ref.watch(getWalletProvider)();
}

final walletProvider =
    AsyncNotifierProvider<WalletNotifier, Wallet?>(WalletNotifier.new);

final walletAddressProvider = Provider<String?>(
  (ref) => ref.watch(walletProvider).value?.address,
);
