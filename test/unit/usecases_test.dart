import 'package:crypto_wallet/core/errors/failures.dart';
import 'package:crypto_wallet/features/assets/domain/usecases/assets_usecases.dart';
import 'package:crypto_wallet/features/authentication/domain/usecases/auth_usecases.dart';
import 'package:crypto_wallet/features/send/domain/usecases/prepare_send.dart';
import 'package:crypto_wallet/features/transactions/domain/entities/wallet_transaction.dart';
import 'package:crypto_wallet/features/transactions/domain/usecases/transaction_usecases.dart';
import 'package:crypto_wallet/features/wallet/domain/usecases/restore_wallet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';

class MockGetBalance extends Mock implements GetBalance {}

class MockEstimateGas extends Mock implements EstimateGas {}

void main() {
  const recipient = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8';
  const sender = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
  final estimate = FeeEstimate(
    gasLimit: BigInt.from(21000),
    gasPrice: BigInt.from(1000000000),
  );
  final ether = BigInt.parse('1000000000000000000');

  group('RestoreWallet', () {
    test('rejects invalid mnemonic', () {
      final usecase = RestoreWallet(FakeWalletRepository());
      expect(() => usecase('bad phrase', 'sepolia'),
          throwsA(isA<WalletFailure>()));
    });

    test('restores wallet from valid mnemonic', () async {
      final usecase = RestoreWallet(FakeWalletRepository());
      final wallet = await usecase(
        'test test test test test test test test test test test junk',
        'sepolia',
      );
      expect(wallet.address, '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266');
    });
  });

  group('SetupPin', () {
    test('rejects short PIN', () {
      expect(() => SetupPin(FakeAuthRepository())('123'),
          throwsA(isA<AuthenticationFailure>()));
    });

    test('stores valid PIN', () async {
      final repo = FakeAuthRepository();
      await SetupPin(repo)('123456');
      expect(await repo.hasPin(), isTrue);
    });
  });

  group('PrepareSend', () {
    late MockGetBalance balance;
    late MockEstimateGas gas;
    late PrepareSend prepare;

    setUpAll(() => registerFallbackValue(BigInt.zero));

    setUp(() {
      balance = MockGetBalance();
      gas = MockEstimateGas();
      prepare = PrepareSend(balance, gas);
      when(() => balance(sender)).thenAnswer((_) async => ether);
      when(() => gas(
            from: any(named: 'from'),
            to: any(named: 'to'),
            amount: any(named: 'amount'),
          )).thenAnswer((_) async => estimate);
    });

    Future<SendRequest> run(String to, String amount) => prepare(
          from: sender,
          to: to,
          amountText: amount,
          decimals: 18,
        );

    test('returns request for valid input', () async {
      final request = await run(recipient, '0.5');
      expect(request.amount, ether ~/ BigInt.two);
      expect(request.estimate.fee, BigInt.from(21000000000000));
    });

    test('rejects invalid address', () {
      expect(run('0x123', '1'), throwsA(isA<InvalidAddressFailure>()));
    });

    test('rejects zero amount', () {
      expect(run(recipient, '0'), throwsA(isA<InvalidAmountFailure>()));
    });

    test('rejects amount above balance', () {
      expect(run(recipient, '2'), throwsA(isA<InsufficientBalanceFailure>()));
    });

    test('rejects when amount plus fee exceeds balance', () {
      expect(run(recipient, '1'), throwsA(isA<InsufficientBalanceFailure>()));
    });
  });
}
