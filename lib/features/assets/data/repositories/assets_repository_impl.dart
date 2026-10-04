import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../shared/models/network.dart';
import '../../../wallet/data/datasources/blockchain_datasource.dart';
import '../../domain/entities/asset.dart';
import '../../domain/repositories/assets_repository.dart';

class AssetsRepositoryImpl implements AssetsRepository {
  const AssetsRepositoryImpl(this._blockchain, this._cache, this._network);

  final BlockchainDataSource _blockchain;
  final Box<String> _cache;
  final Network _network;

  String _key(String address) =>
      'assets:${_network.chainId}:${address.toLowerCase()}';

  Asset _native(BigInt balance) => Asset(
        id: 'native:${_network.chainId}',
        symbol: _network.nativeCurrency.symbol,
        name: _network.nativeCurrency.name,
        decimals: _network.nativeCurrency.decimals,
        balance: balance,
      );

  Asset _token(TokenInfo token, BigInt balance) => Asset(
        id: 'token:${_network.chainId}:${token.contractAddress.toLowerCase()}',
        symbol: token.symbol,
        name: token.name,
        decimals: token.decimals,
        balance: balance,
        contractAddress: token.contractAddress,
      );

  Map<String, dynamic> _readCache(String address) {
    final raw = _cache.get(_key(address));
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeCache(
    String address, {
    String? balance,
    Map<String, String>? tokens,
  }) async {
    final current = _readCache(address);
    final mergedTokens = Map<String, String>.from(
      (current['tokens'] as Map?)?.map(
            (key, value) => MapEntry('$key', '$value'),
          ) ??
          const {},
    );
    if (tokens != null) mergedTokens.addAll(tokens);
    await _cache.put(
      _key(address),
      jsonEncode({
        'balance': balance ?? current['balance'] ?? '0',
        'tokens': mergedTokens,
      }),
    );
  }

  @override
  List<Asset>? getCachedAssets(String address) {
    final json = _readCache(address);
    if (json.isEmpty || json['balance'] == null) return null;
    try {
      final tokens = (json['tokens'] as Map<String, dynamic>?) ?? const {};
      return [
        _native(BigInt.parse(json['balance'] as String)),
        for (final token in _network.tokens)
          _token(
            token,
            BigInt.parse(
              (tokens[token.contractAddress.toLowerCase()] as String?) ?? '0',
            ),
          ),
      ];
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Asset> getNativeAsset(String address) async {
    final balance = await _blockchain.getBalance(address);
    await _writeCache(address, balance: balance.toString());
    return _native(balance);
  }

  Future<BigInt> _tokenBalance(TokenInfo token, String address) async {
    try {
      return await _blockchain.getTokenBalance(address, token.contractAddress);
    } catch (_) {
      return BigInt.zero;
    }
  }

  @override
  Future<List<Asset>> getAssets(String address) async {
    final native = await _blockchain.getBalance(address);
    final tokenBalances = await Future.wait([
      for (final token in _network.tokens) _tokenBalance(token, address),
    ]);
    await _writeCache(
      address,
      balance: native.toString(),
      tokens: {
        for (var i = 0; i < _network.tokens.length; i++)
          _network.tokens[i].contractAddress.toLowerCase():
              tokenBalances[i].toString(),
      },
    );
    return [
      _native(native),
      for (var i = 0; i < _network.tokens.length; i++)
        _token(_network.tokens[i], tokenBalances[i]),
    ];
  }
}
