import 'package:crypto_wallet/core/errors/failures.dart';
import 'package:crypto_wallet/core/security/pin_hasher.dart';
import 'package:crypto_wallet/core/utils/units.dart';
import 'package:crypto_wallet/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Units', () {
    test('formats wei to ether', () {
      expect(Units.format(BigInt.parse('123456789000000000'), 18),
          '0.123456789');
      expect(Units.format(BigInt.parse('1234567890000000000'), 18),
          '1.23456789');
      expect(Units.format(BigInt.zero, 18), '0');
      expect(Units.format(BigInt.parse('1000000000000000000'), 18), '1');
    });

    test('truncates to max fraction', () {
      expect(
        Units.format(BigInt.parse('1234567890000000000'), 18, maxFraction: 4),
        '1.2345',
      );
    });

    test('parses decimal strings exactly', () {
      expect(Units.parse('1.5', 18), BigInt.parse('1500000000000000000'));
      expect(Units.parse('0,01', 18), BigInt.parse('10000000000000000'));
      expect(Units.parse('.5', 18), BigInt.parse('500000000000000000'));
      expect(Units.parse('1', 6), BigInt.from(1000000));
    });

    test('rejects invalid amounts', () {
      for (final bad in ['', 'abc', '1.2.3', '-1', '.', '1e5']) {
        expect(() => Units.parse(bad, 18), throwsA(isA<InvalidAmountFailure>()));
      }
      expect(() => Units.parse('0.1234567', 6), throwsA(isA<InvalidAmountFailure>()));
    });
  });

  group('Validators', () {
    test('accepts valid addresses', () {
      expect(Validators.isValidAddress('0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'), isTrue);
      expect(Validators.isValidAddress('0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266'), isTrue);
    });

    test('rejects invalid addresses', () {
      expect(Validators.isValidAddress('0x123'), isFalse);
      expect(Validators.isValidAddress('f39Fd6e51aad88F6F4ce6aB8827279cffFb92266'), isFalse);
      expect(Validators.isValidAddress('0xf39Fd6e51aad88F6F4ce6aB8827279cffFb9226G'), isFalse);
    });

    test('rejects wrong checksum', () {
      expect(Validators.isValidAddress('0xF39Fd6e51aad88F6F4ce6aB8827279cffFb92266'), isFalse);
    });

    test('validates PIN', () {
      expect(Validators.isValidPin('123456', 6), isTrue);
      expect(Validators.isValidPin('12345', 6), isFalse);
      expect(Validators.isValidPin('12345a', 6), isFalse);
    });
  });

  group('PinHasher', () {
    test('verifies correct pin and rejects wrong one', () {
      final salt = PinHasher.generateSalt();
      final hash = PinHasher.hash('123456', salt, rounds: 100);
      expect(PinHasher.verify('123456', salt, hash, rounds: 100), isTrue);
      expect(PinHasher.verify('654321', salt, hash, rounds: 100), isFalse);
    });

    test('salt changes hash', () {
      final a = PinHasher.hash('123456', PinHasher.generateSalt(), rounds: 10);
      final b = PinHasher.hash('123456', PinHasher.generateSalt(), rounds: 10);
      expect(a, isNot(b));
    });
  });
}
