import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/security/authorization_token.dart';
import '../../../../core/utils/units.dart';
import '../../../assets/presentation/providers/assets_provider.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/domain/entities/wallet_transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/usecases/prepare_send.dart';

enum SendStatus { idle, preparing, ready, sending, sent, error }

class SendAssetOption {
  const SendAssetOption({
    required this.symbol,
    required this.decimals,
    this.contractAddress,
  });

  final String symbol;
  final int decimals;
  final String? contractAddress;

  bool get isToken => contractAddress != null;
}

class SendState {
  const SendState({
    this.status = SendStatus.idle,
    this.request,
    this.transaction,
    this.error,
    this.selected,
  });

  final SendStatus status;
  final SendRequest? request;
  final WalletTransaction? transaction;
  final String? error;
  final SendAssetOption? selected;
}

final prepareSendProvider = Provider(
  (ref) => PrepareSend(
    ref.watch(getBalanceProvider),
    ref.watch(getTokenBalanceProvider),
    ref.watch(estimateGasProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);

class SendNotifier extends Notifier<SendState> {
  @override
  SendState build() {
    final network = ref.watch(currentNetworkProvider);
    return SendState(
      selected: SendAssetOption(
        symbol: network.nativeCurrency.symbol,
        decimals: network.nativeCurrency.decimals,
      ),
    );
  }

  void selectAsset(SendAssetOption asset) {
    state = SendState(selected: asset);
  }

  void setInitial({
    required String symbol,
    required int decimals,
    String? contractAddress,
  }) {
    state = SendState(
      selected: SendAssetOption(
        symbol: symbol,
        decimals: decimals,
        contractAddress: contractAddress,
      ),
    );
  }

  Future<void> prepare(String to, String amountText) async {
    final from = ref.read(walletAddressProvider);
    final selected = state.selected;
    if (from == null || selected == null) return;
    state = SendState(status: SendStatus.preparing, selected: selected);
    try {
      final request = await ref.read(prepareSendProvider)(
        from: from,
        to: to,
        amountText: amountText,
        decimals: selected.decimals,
        asset: selected.symbol,
        tokenContract: selected.contractAddress,
      );
      state = SendState(
        status: SendStatus.ready,
        request: request,
        selected: selected,
      );
    } catch (e) {
      state = SendState(
        status: SendStatus.error,
        selected: selected,
        error: Failure.from(e).message,
      );
    }
  }

  Future<String?> maxAmount(String to) async {
    final from = ref.read(walletAddressProvider);
    final selected = state.selected;
    if (from == null || selected == null) return null;
    try {
      final max = await ref.read(prepareSendProvider).maxSendable(
            from: from,
            to: to,
            decimals: selected.decimals,
            tokenContract: selected.contractAddress,
          );
      return Units.format(max, selected.decimals, maxFraction: 8);
    } catch (_) {
      return null;
    }
  }

  Future<void> confirm(AuthorizationToken auth) async {
    final request = state.request;
    final selected = state.selected;
    if (request == null || state.status != SendStatus.ready) return;
    state = SendState(
      status: SendStatus.sending,
      request: request,
      selected: selected,
    );
    try {
      final from = ref.read(walletAddressProvider)!;
      final estimate = await ref.read(estimateGasProvider)(
        from: from,
        to: request.to,
        amount: request.amount,
        tokenContract: request.tokenContract,
      );
      final refreshed = request.copyWith(estimate: estimate);
      final mnemonic = ref.read(sessionProvider.notifier).unlockedMnemonic;
      if (mnemonic == null) {
        throw const AuthenticationFailure('Wallet is locked.');
      }
      final tx = await ref.read(sendTransactionProvider)(
        refreshed,
        auth,
        mnemonic,
      );
      state = SendState(
        status: SendStatus.sent,
        request: refreshed,
        transaction: tx,
        selected: selected,
      );
      ref.read(transactionsProvider.notifier).refresh();
      ref.read(assetsProvider.notifier).refresh();
    } catch (e) {
      state = SendState(
        status: SendStatus.error,
        request: request,
        selected: selected,
        error: Failure.from(e).message,
      );
    }
  }

  void reset() {
    final network = ref.read(currentNetworkProvider);
    final selected = state.selected ??
        SendAssetOption(
          symbol: network.nativeCurrency.symbol,
          decimals: network.nativeCurrency.decimals,
        );
    state = SendState(selected: selected);
  }
}

final sendProvider = NotifierProvider<SendNotifier, SendState>(SendNotifier.new);
