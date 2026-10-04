import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/models/network.dart';
import '../../../wallet/data/datasources/blockchain_datasource.dart';
import '../../../wallet/data/datasources/wallet_local_datasource.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(
    this._blockchain,
    this._remote,
    this._wallet,
    this._cache,
    this._network,
  );

  final BlockchainDataSource _blockchain;
  final TransactionRemoteDataSource _remote;
  final WalletLocalDataSource _wallet;
  final Box<String> _cache;
  final Network _network;

  String _remoteKey(String address) =>
      'txs:${_network.chainId}:${address.toLowerCase()}';

  String _localKey(String address) =>
      'sent:${_network.chainId}:${address.toLowerCase()}';

  static int _statusRank(TxStatus status) => switch (status) {
        TxStatus.confirmed || TxStatus.failed || TxStatus.dropped => 2,
        TxStatus.pending => 1,
      };

  static TxStatus _preferStatus(TxStatus a, TxStatus b) =>
      _statusRank(a) >= _statusRank(b) ? a : b;

  List<WalletTransaction> _read(String key) {
    final raw = _cache.get(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(String key, List<WalletTransaction> txs) =>
      _cache.put(key, jsonEncode(txs.map(TransactionModel.toJson).toList()));

  List<WalletTransaction> _merge(
    List<WalletTransaction> remote,
    List<WalletTransaction> local,
  ) {
    final byHash = <String, WalletTransaction>{};
    for (final tx in local) {
      byHash[tx.hash.toLowerCase()] = tx;
    }
    for (final tx in remote) {
      final key = tx.hash.toLowerCase();
      final existing = byHash[key];
      byHash[key] = existing == null
          ? tx
          : tx.copyWith(status: _preferStatus(existing.status, tx.status));
    }
    return byHash.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> _updateLocalStatus(
    String address,
    String hash,
    TxStatus status,
  ) async {
    final key = _localKey(address);
    final updated = _read(key)
        .map(
          (tx) => tx.hash.toLowerCase() == hash.toLowerCase()
              ? tx.copyWith(status: status)
              : tx,
        )
        .toList();
    await _write(key, updated);
  }

  @override
  List<WalletTransaction>? getCachedTransactions(String address) {
    final merged =
        _merge(_read(_remoteKey(address)), _read(_localKey(address)));
    return merged.isEmpty ? null : merged;
  }

  @override
  Future<List<WalletTransaction>> getTransactions(String address) async {
    final local = _read(_localKey(address));
    try {
      final rows = await _remote.fetch(address);
      final remote = [
        for (final json in rows)
          TransactionModel.fromExplorer(
            json,
            owner: address,
            symbol: _network.nativeCurrency.symbol,
            decimals: _network.nativeCurrency.decimals,
          ),
      ];
      if (_remote.isConfigured) await _write(_remoteKey(address), remote);
      return _merge(remote, local);
    } catch (e) {
      final fallback = getCachedTransactions(address);
      if (fallback != null) return fallback;
      throw Failure.from(e);
    }
  }

  @override
  Future<WalletTransaction?> getTransaction(String address, String hash) async {
    final list =
        getCachedTransactions(address) ?? await getTransactions(address);
    for (final tx in list) {
      if (tx.hash.toLowerCase() == hash.toLowerCase()) return tx;
    }
    return null;
  }

  @override
  Future<FeeEstimate> estimateFee({
    required String from,
    required String to,
    required BigInt amount,
  }) async {
    final result =
        await _blockchain.estimateFee(from: from, to: to, amount: amount);
    return FeeEstimate(gasLimit: result.gasLimit, gasPrice: result.gasPrice);
  }

  @override
  Future<WalletTransaction> sendTransaction(SendRequest request) async {
    final credentials = await _wallet.loadCredentials();
    final from = credentials.address.hexEip55;
    final hash = await _blockchain.signAndSend(
      credentials: credentials,
      to: request.to,
      amount: request.amount,
      gasLimit: request.estimate.gasLimit,
      gasPrice: request.estimate.gasPrice,
    );
    final tx = WalletTransaction(
      hash: hash,
      from: from,
      to: request.to,
      amount: request.amount,
      asset: _network.nativeCurrency.symbol,
      decimals: _network.nativeCurrency.decimals,
      fee: request.estimate.fee,
      status: TxStatus.pending,
      timestamp: DateTime.now(),
      type: TxType.sent,
    );
    await _write(_localKey(from), [tx, ..._read(_localKey(from))]);
    return tx;
  }

  @override
  Future<TxStatus> trackTransaction(String address, String hash) async {
    final status = await _blockchain.receiptStatus(hash) ?? TxStatus.pending;
    if (status != TxStatus.pending) {
      await _updateLocalStatus(address, hash, status);
    }
    return status;
  }

  @override
  Future<void> markDropped(String address, String hash) =>
      _updateLocalStatus(address, hash, TxStatus.dropped);
}
