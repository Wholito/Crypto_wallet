import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../assets/presentation/providers/assets_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/domain/entities/wallet_transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/usecases/prepare_send.dart';

enum SendStatus { idle, preparing, ready, sending, sent, error }

class SendState {
  const SendState({
    this.status = SendStatus.idle,
    this.request,
    this.transaction,
    this.error,
  });

  final SendStatus status;
  final SendRequest? request;
  final WalletTransaction? transaction;
  final String? error;
}

final prepareSendProvider = Provider(
  (ref) => PrepareSend(ref.watch(getBalanceProvider), ref.watch(estimateGasProvider)),
);

class SendNotifier extends Notifier<SendState> {
  @override
  SendState build() => const SendState();

  Future<void> prepare(String to, String amountText) async {
    final from = ref.read(walletAddressProvider);
    if (from == null) return;
    state = const SendState(status: SendStatus.preparing);
    try {
      final request = await ref.read(prepareSendProvider)(
        from: from,
        to: to,
        amountText: amountText,
        decimals: ref.read(currentNetworkProvider).nativeCurrency.decimals,
      );
      state = SendState(status: SendStatus.ready, request: request);
    } catch (e) {
      state = SendState(status: SendStatus.error, error: Failure.from(e).message);
    }
  }

  Future<void> confirm() async {
    final request = state.request;
    if (request == null || state.status != SendStatus.ready) return;
    state = SendState(status: SendStatus.sending, request: request);
    try {
      final tx = await ref.read(sendTransactionProvider)(request);
      state = SendState(status: SendStatus.sent, request: request, transaction: tx);
      ref.read(transactionsProvider.notifier).refresh();
    } catch (e) {
      state = SendState(
        status: SendStatus.error,
        request: request,
        error: Failure.from(e).message,
      );
    }
  }

  void reset() => state = const SendState();
}

final sendProvider = NotifierProvider<SendNotifier, SendState>(SendNotifier.new);
