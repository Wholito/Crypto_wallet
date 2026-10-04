import 'dart:io';

import 'package:crypto_wallet/core/constants/networks.dart';
import 'package:crypto_wallet/core/errors/failures.dart';
import 'package:crypto_wallet/features/assets/data/repositories/assets_repository_impl.dart';
import 'package:crypto_wallet/features/wallet/data/datasources/blockchain_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class _TokenFailBlockchain extends BlockchainDataSource {
  _TokenFailBlockchain() : super(Networks.bnb, http.Client());

  @override
  Future<BigInt> getBalance(String address) async => BigInt.from(5);

  @override
  Future<BigInt> getTokenBalance(String address, String contract) async {
    throw const NetworkFailure('token down');
  }
}

void main() {
  test('Failure.from maps unknown errors to UnknownFailure', () {
    final failure = Failure.from(StateError('bug'));
    expect(failure, isA<UnknownFailure>());
    expect(failure.message, 'Something went wrong.');
  });

  test('getAssets keeps native balance when token fails', () async {
    final dir = await Directory.systemTemp.createTemp('assets_fail');
    Hive.init(dir.path);
    final box = await Hive.openBox<String>('assets_fail');
    addTearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    final repo = AssetsRepositoryImpl(_TokenFailBlockchain(), box, Networks.bnb);
    final assets = await repo.getAssets('0x0000000000000000000000000000000000000001');
    expect(assets.first.symbol, 'BNB');
    expect(assets.first.balance, BigInt.from(5));
    expect(assets.last.symbol, 'USDT');
    expect(assets.last.balance, BigInt.zero);
  });
}
