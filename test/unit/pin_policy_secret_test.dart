import 'package:crypto_wallet/core/security/pin_policy.dart';
import 'package:crypto_wallet/core/security/secret_box.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects trivial pins', () {
    expect(PinPolicy.isTrivial('000000'), isTrue);
    expect(PinPolicy.isTrivial('123456'), isTrue);
    expect(PinPolicy.isTrivial('654321'), isTrue);
    expect(PinPolicy.isTrivial('258041'), isFalse);
  });

  test('aes gcm round trip with pin', () async {
    const saltB64 = 'dGVzdC1zYWx0LXZhbHVlLTE2';
    final sealed = await SecretBox.sealWithPin('one two three', '258041', saltB64);
    final opened = await SecretBox.openWithPin(sealed, '258041', saltB64);
    expect(opened, 'one two three');
  });
}
