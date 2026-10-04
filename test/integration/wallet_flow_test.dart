import 'package:crypto_wallet/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

Future<void> _enterPin(WidgetTester tester, [String pin = '123456']) async {
  for (final d in pin.split('')) {
    await tester.tap(find.byKey(Key('pin_$d')));
  }
  await tester.pumpAndSettle();
}

void main() {
  const recipient = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8';

  testWidgets('create wallet, view balance, receive, send, history',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final auth = FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: fakeOverrides(auth: auth),
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create_wallet_button')));
    await tester.pumpAndSettle();

    final words = <String>[];
    for (var i = 0; i < 12; i++) {
      final label = tester.widget<Text>(find.descendant(
        of: find.byKey(Key('seed_word_$i')),
        matching: find.byType(Text),
      ));
      words.add(label.data!.split('. ').last);
    }
    await tester.tap(find.byKey(const Key('backup_checkbox')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('backup_continue')));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      final field = tester.widget<TextField>(find.byKey(Key('quiz_$i')));
      final number = int.parse(field.decoration!.labelText!.split('#').last);
      await tester.enterText(find.byKey(Key('quiz_$i')), words[number - 1]);
    }
    await tester.tap(find.byKey(const Key('verify_continue')));
    await tester.pumpAndSettle();

    await _enterPin(tester);
    await _enterPin(tester);

    expect(auth.pin, '123456');
    expect(find.byKey(const Key('balance_text')), findsOneWidget);
    expect(find.text('1.5 SepoliaETH'), findsWidgets);

    await tester.tap(find.byKey(const Key('receive_action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('qr_code')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('send_action')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('recipient_field')), recipient);
    await tester.enterText(find.byKey(const Key('amount_field')), '0.25');
    await tester.tap(find.byKey(const Key('review_button')));
    await tester.pumpAndSettle();

    expect(find.text('Confirm transaction'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm_send')));
    await tester.pumpAndSettle();
    await _enterPin(tester);

    expect(find.byKey(const Key('detail_status')), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history_action')));
    await tester.pumpAndSettle();
    expect(find.text('-0.25 SepoliaETH'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('existing wallet requires PIN to unlock', (tester) async {
    final wallet = FakeWalletRepository();
    await wallet.createWallet(
      'test test test test test test test test test test test junk',
      'sepolia',
    );
    final auth = FakeAuthRepository()..pin = '123456';
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: fakeOverrides(wallet: wallet, auth: auth),
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Enter PIN'), findsOneWidget);

    await _enterPin(tester, '000000');
    expect(find.text('Wrong PIN.'), findsOneWidget);

    await _enterPin(tester);
    expect(find.byKey(const Key('balance_text')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
