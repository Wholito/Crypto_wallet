import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/http_providers.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../assets/presentation/providers/assets_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../data/datasources/transaction_remote_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/transaction_usecases.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final network = ref.watch(currentNetworkProvider);
  return TransactionRepositoryImpl(
    ref.watch(blockchainDataSourceProvider),
    TransactionRemoteDataSource(ref.watch(httpClientProvider), network),
    ref.watch(walletLocalDataSourceProvider),
    ref.watch(cacheBoxProvider),
    network,
  );
});

final getTransactionsProvider = Provider(
  (ref) => GetTransactions(ref.watch(transactionRepositoryProvider)),
);
final getTransactionProvider = Provider(
  (ref) => GetTransaction(ref.watch(transactionRepositoryProvider)),
);
final estimateGasProvider = Provider(
  (ref) => EstimateGas(ref.watch(transactionRepositoryProvider)),
);
final sendTransactionProvider = Provider(
  (ref) => SendTransaction(ref.watch(transactionRepositoryProvider)),
);
final trackTransactionProvider = Provider(
  (ref) => TrackTransaction(ref.watch(transactionRepositoryProvider)),
);

class TransactionsNotifier extends AsyncNotifier<List<WalletTransaction>> {
  Timer? _timer;
  final Map<String, DateTime> _pendingSince = {};
  int _pollAttempt = 0;

  @override
  Future<List<WalletTransaction>> build() async {
    ref.onDispose(() => _timer?.cancel());
    final address = ref.watch(walletAddressProvider);
    if (address == null) return const [];
    final get = ref.watch(getTransactionsProvider);
    final cached = get.cached(address);
    if (cached != null) {
      _schedule(cached);
      Future.microtask(() {
        if (ref.mounted) refresh();
      });
      return cached;
    }
    final list = await get(address);
    _schedule(list);
    return list;
  }

  Future<void> refresh() async {
    final address = ref.read(walletAddressProvider);
    final chainId = ref.read(currentNetworkProvider).chainId;
    if (address == null) return;
    final previous = state;
    try {
      final list = await ref.read(getTransactionsProvider)(address);
      if (!ref.mounted) return;
      if (ref.read(walletAddressProvider) != address ||
          ref.read(currentNetworkProvider).chainId != chainId) {
        return;
      }
      state = AsyncData(list);
      _schedule(list);
    } catch (error, stack) {
      if (ref.mounted) {
        state = AsyncError<List<WalletTransaction>>(error, stack);
        _schedule(previous.value ?? const []);
      }
    }
  }

  void _schedule(List<WalletTransaction> list) {
    _timer?.cancel();
    final now = DateTime.now();
    for (final tx in list.where((tx) => tx.status == TxStatus.pending)) {
      _pendingSince.putIfAbsent(tx.hash.toLowerCase(), () => tx.timestamp);
    }
    _pendingSince.removeWhere(
      (hash, _) => !list.any(
        (tx) =>
            tx.hash.toLowerCase() == hash && tx.status == TxStatus.pending,
      ),
    );
    if (_pendingSince.isEmpty) {
      _pollAttempt = 0;
      return;
    }
    final delaySeconds = (5 * (1 << _pollAttempt.clamp(0, 4))).clamp(5, 80);
    _timer = Timer(Duration(seconds: delaySeconds), () => _poll(now));
  }

  Future<void> _poll(DateTime scheduledAt) async {
    final address = ref.read(walletAddressProvider);
    final chainId = ref.read(currentNetworkProvider).chainId;
    final pending = (state.value ?? const <WalletTransaction>[])
        .where((tx) => tx.status == TxStatus.pending)
        .toList();
    if (address == null || pending.isEmpty) return;
    var changed = false;
    final repo = ref.read(transactionRepositoryProvider);
    for (final tx in pending) {
      final started = _pendingSince[tx.hash.toLowerCase()] ?? tx.timestamp;
      if (DateTime.now().difference(started) >= AppConstants.pendingTxTimeout) {
        await repo.markDropped(address, tx.hash);
        changed = true;
        continue;
      }
      try {
        final status =
            await ref.read(trackTransactionProvider)(address, tx.hash);
        if (status != TxStatus.pending) changed = true;
      } catch (_) {}
      if (!ref.mounted) return;
      if (ref.read(walletAddressProvider) != address ||
          ref.read(currentNetworkProvider).chainId != chainId) {
        return;
      }
    }
    if (changed) {
      _pollAttempt = 0;
      await refresh();
      if (ref.mounted) ref.read(assetsProvider.notifier).refresh();
    } else {
      _pollAttempt++;
      _schedule(state.value ?? const []);
    }
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<WalletTransaction>>(
  TransactionsNotifier.new,
);
