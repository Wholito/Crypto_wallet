import 'package:crypto_wallet/shared/widgets/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PinPad reports pin after six digits', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PinPad(title: 'PIN', onCompleted: (pin) => result = pin),
          ),
        ),
      ),
    );
    for (final d in '123456'.split('')) {
      await tester.tap(find.byKey(Key('pin_$d')));
    }
    expect(result, '123456');
  });

  testWidgets('PinPad backspace removes digit', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PinPad(title: 'PIN', onCompleted: (pin) => result = pin),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('pin_1')));
    await tester.tap(find.byKey(const Key('pin_2')));
    await tester.tap(find.byKey(const Key('pin_backspace')));
    for (final d in '23456'.split('')) {
      await tester.tap(find.byKey(Key('pin_$d')));
    }
    expect(result, '123456');
  });
}
