import 'package:crypto_wallet/core/constants/networks.dart';
import 'package:crypto_wallet/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:crypto_wallet/features/receive/presentation/pages/receive_page.dart';
import 'package:crypto_wallet/features/receive/presentation/providers/receive_provider.dart';
import 'package:crypto_wallet/features/send/presentation/pages/send_page.dart';
import 'package:crypto_wallet/features/settings/presentation/pages/settings_page.dart';
import 'package:crypto_wallet/features/settings/presentation/providers/settings_provider.dart';
import 'package:crypto_wallet/features/transactions/domain/entities/wallet_transaction.dart';
import 'package:crypto_wallet/features/transactions/presentation/pages/transactions_page.dart';
import 'package:crypto_wallet/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../helpers/fakes.dart';

const _address = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [...fakeOverrides(), ...overrides],
      child: MaterialApp(home: child),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeTransactions extends TransactionsNotifier {
  @override
  Future<List<WalletTransaction>> build() async => [
        WalletTransaction(
          hash: '0xabc',
          from: _address,
          to: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
          amount: BigInt.parse('500000000000000000'),
          asset: 'SepoliaETH',
          decimals: 18,
          fee: BigInt.zero,
          status: TxStatus.confirmed,
          timestamp: DateTime(2026, 1, 2, 3, 4),
          type: TxType.sent,
        ),
      ];
}

void main() {
  testWidgets('welcome page shows create and restore actions', (tester) async {
    await _pump(tester, const WelcomePage());
    expect(find.byKey(const Key('create_wallet_button')), findsOneWidget);
    expect(find.byKey(const Key('restore_wallet_button')), findsOneWidget);
  });

  testWidgets('receive page shows address and QR code', (tester) async {
    await _pump(
      tester,
      const ReceivePage(),
      overrides: [receiveAddressProvider.overrideWith((ref) async => _address)],
    );
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text(_address), findsOneWidget);
  });

  testWidgets('send page validates required fields', (tester) async {
    await _pump(tester, const SendPage());
    await tester.tap(find.byKey(const Key('review_button')));
    await tester.pump();
    expect(find.text('Enter recipient address'), findsOneWidget);
    expect(find.text('Enter amount'), findsOneWidget);
  });

  testWidgets('transactions page lists transactions', (tester) async {
    await _pump(
      tester,
      const TransactionsPage(),
      overrides: [transactionsProvider.overrideWith(_FakeTransactions.new)],
    );
    expect(find.text('-0.5 SepoliaETH'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
  });

  testWidgets('settings page switches network', (tester) async {
    await _pump(tester, const SettingsPage());
    expect(find.byKey(const Key('network_polygon')), findsOneWidget);
    await tester.tap(find.byKey(const Key('network_polygon')));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsPage)),
    );
    expect(container.read(settingsProvider).network, Networks.polygon);
  });
}
