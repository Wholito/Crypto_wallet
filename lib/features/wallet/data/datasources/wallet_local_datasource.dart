import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/web3dart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/security/hd_wallet.dart';
import '../models/wallet_model.dart';

class WalletLocalDataSource {
  const WalletLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;

  static const _mnemonicKey = 'wallet_mnemonic';
  static const _metaKey = 'wallet_meta';

  Future<void> save(String mnemonic, WalletModel wallet) async {
    try {
      await _storage.write(key: _mnemonicKey, value: mnemonic);
      await _storage.write(key: _metaKey, value: wallet.encode());
    } catch (_) {
      throw const StorageFailure('Unable to save wallet securely.');
    }
  }

  Future<bool> hasMnemonic() async {
    try {
      return await _storage.read(key: _mnemonicKey) != null;
    } catch (_) {
      throw const StorageFailure();
    }
  }

  Future<WalletModel?> readMeta() async {
    try {
      final raw = await _storage.read(key: _metaKey);
      return raw == null ? null : WalletModel.decode(raw);
    } catch (_) {
      throw const StorageFailure('Unable to read wallet.');
    }
  }

  Future<String> readMnemonic() async {
    try {
      final mnemonic = await _storage.read(key: _mnemonicKey);
      if (mnemonic == null) throw const WalletFailure('Wallet not found.');
      return mnemonic;
    } on Failure {
      rethrow;
    } catch (_) {
      throw const StorageFailure('Unable to read wallet.');
    }
  }

  Future<EthPrivateKey> loadCredentials() async =>
      HdWallet.credentialsAsync(await readMnemonic());

  Future<void> clear() async {
    try {
      await _storage.delete(key: _mnemonicKey);
      await _storage.delete(key: _metaKey);
    } catch (_) {
      throw const StorageFailure('Unable to delete wallet.');
    }
  }
}
