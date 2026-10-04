import 'dart:io';

import 'package:crypto_wallet/core/constants/networks.dart';
import 'package:crypto_wallet/features/assets/data/repositories/assets_repository_impl.dart';
import 'package:crypto_wallet/features/wallet/data/datasources/blockchain_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class _FakeBlockchain extends BlockchainDataSource {
  _FakeBlockchain() : super(Networks.bnb, http.Client());

  @override
  Future<BigInt> getBalance(String address) async => BigInt.parse('2000000000000000000');

  @override
  Future<BigInt> getTokenBalance(String address, String contract) async =>
      BigInt.parse('12500000000000000000');
}

void main() {
  late Directory dir;
  late Box<String> box;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(dir.path);
    box = await Hive.openBox<String>('assets_test');
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('BNB Chain returns native BNB and USDT', () async {
    final repo = AssetsRepositoryImpl(_FakeBlockchain(), box, Networks.bnb);
    const address = '0x0000000000000000000000000000000000000001';

    final assets = await repo.getAssets(address);

    expect(assets.map((a) => a.symbol), ['BNB', 'USDT']);
    expect(assets[0].formattedBalance, '2');
    expect(assets[1].formattedBalance, '12.5');
    expect(assets[1].contractAddress, Networks.bnb.tokens.first.contractAddress);

    final cached = repo.getCachedAssets(address)!;
    expect(cached.map((a) => a.formattedBalance), ['2', '12.5']);
  });
}
