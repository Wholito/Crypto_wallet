import 'package:crypto_wallet/core/constants/networks.dart';
import 'package:crypto_wallet/features/send/presentation/providers/send_provider.dart';
import 'package:crypto_wallet/features/settings/presentation/providers/settings_provider.dart';
import 'package:crypto_wallet/features/transactions/domain/entities/wallet_transaction.dart';
import 'package:crypto_wallet/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:crypto_wallet/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

class _FakeTransactions extends TransactionsNotifier {
  @override
  Future<List<WalletTransaction>> build() async => const [];

  @override
  Future<void> refresh() async {}
}

void main() {
  const recipient = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8';

  ProviderContainer container(FakeTransactionRepository txs, BigInt balance) {
    final c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        ...fakeOverrides(
          transactions: txs,
          assets: FakeAssetsRepository(balance),
        ),
        walletAddressProvider.overrideWithValue(
          '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
        ),
        currentNetworkProvider.overrideWithValue(Networks.sepolia),
        transactionsProvider.overrideWith(_FakeTransactions.new),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('prepare then confirm sends transaction', () async {
    final txs = FakeTransactionRepository();
    final c = container(txs, BigInt.parse('1000000000000000000'));
    final notifier = c.read(sendProvider.notifier);

    await notifier.prepare(recipient, '0.1');
    expect(c.read(sendProvider).status, SendStatus.ready);

    await notifier.confirm();
    final state = c.read(sendProvider);
    expect(state.status, SendStatus.sent);
    expect(state.transaction!.status, TxStatus.pending);
    expect(txs.sent, hasLength(1));
  });

  test('prepare reports insufficient balance', () async {
    final c = container(FakeTransactionRepository(), BigInt.from(1000));
    await c.read(sendProvider.notifier).prepare(recipient, '1');
    final state = c.read(sendProvider);
    expect(state.status, SendStatus.error);
    expect(state.error, 'Insufficient balance.');
  });

  test('confirm without prepare does nothing', () async {
    final txs = FakeTransactionRepository();
    final c = container(txs, BigInt.from(1000));
    await c.read(sendProvider.notifier).confirm();
    expect(txs.sent, isEmpty);
    expect(c.read(sendProvider).status, SendStatus.idle);
  });
}
