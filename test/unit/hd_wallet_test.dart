import 'package:crypto_wallet/core/security/hd_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mnemonic = 'test test test test test test test test test test test junk';

  test('derives known EVM address on m/44\'/60\'/0\'/0/0', () {
    expect(
      HdWallet.addressOf(mnemonic),
      '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
    );
  });

  test('second account differs', () {
    expect(
      HdWallet.addressOf(mnemonic, index: 1),
      '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    );
  });

  test('generated mnemonic is valid and has 12 words', () {
    final generated = HdWallet.generateMnemonic();
    expect(generated.split(' ').length, 12);
    expect(HdWallet.validateMnemonic(generated), isTrue);
  });

  test('generated mnemonics are unique', () {
    expect(HdWallet.generateMnemonic(), isNot(HdWallet.generateMnemonic()));
  });

  test('invalid mnemonic is rejected', () {
    expect(HdWallet.validateMnemonic('foo bar baz'), isFalse);
    expect(
      HdWallet.validateMnemonic(
        'test test test test test test test test test test test test',
      ),
      isFalse,
    );
  });

  test('mnemonic is normalized', () {
    expect(HdWallet.validateMnemonic('  ${mnemonic.toUpperCase()}  '), isTrue);
  });
}
