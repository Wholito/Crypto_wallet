import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/web3dart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/security/hd_wallet.dart';
import '../../../../core/security/secret_box.dart';
import '../models/wallet_model.dart';

class WalletLocalDataSource {
  const WalletLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;

  static const _mnemonicKey = 'wallet_mnemonic';
  static const _mnemonicEncKey = 'wallet_mnemonic_enc';
  static const _mnemonicDeviceKey = 'wallet_mnemonic_device';
  static const _deviceKey = 'wallet_device_key';
  static const _metaKey = 'wallet_meta';

  Future<void> save(String mnemonic, WalletModel wallet) async {
    try {
      await _storage.write(key: _mnemonicKey, value: mnemonic);
      await _storage.delete(key: _mnemonicEncKey);
      await _storage.delete(key: _mnemonicDeviceKey);
      await _storage.write(key: _metaKey, value: wallet.encode());
    } catch (_) {
      throw const StorageFailure('Unable to save wallet securely.');
    }
  }

  Future<void> encryptMnemonic(String pin, String pinSalt) async {
    try {
      final plaintext = await _storage.read(key: _mnemonicKey) ??
          await _decryptDevice();
      if (plaintext == null) throw const WalletFailure('Wallet not found.');
      final enc = await SecretBox.sealWithPin(plaintext, pin, pinSalt);
      final deviceKey = SecretBox.randomBytes(32);
      final devicePayload = SecretBox.seal(plaintext, deviceKey);
      await _storage.write(key: _mnemonicEncKey, value: enc);
      await _storage.write(key: _deviceKey, value: base64Encode(deviceKey));
      await _storage.write(key: _mnemonicDeviceKey, value: devicePayload);
      await _storage.delete(key: _mnemonicKey);
      deviceKey.fillRange(0, deviceKey.length, 0);
    } on Failure {
      rethrow;
    } catch (_) {
      throw const StorageFailure('Unable to encrypt wallet.');
    }
  }

  Future<String?> _decryptDevice() async {
    final payload = await _storage.read(key: _mnemonicDeviceKey);
    final keyB64 = await _storage.read(key: _deviceKey);
    if (payload == null || keyB64 == null) return null;
    final key = base64Decode(keyB64);
    try {
      return SecretBox.open(payload, key);
    } finally {
      key.fillRange(0, key.length, 0);
    }
  }

  Future<String> unlockWithPin(String pin, String pinSalt) async {
    final enc = await _storage.read(key: _mnemonicEncKey);
    if (enc != null) {
      try {
        return await SecretBox.openWithPin(enc, pin, pinSalt);
      } catch (_) {
        final plain = await _storage.read(key: _mnemonicKey);
        if (plain == null) {
          throw const AuthenticationFailure('Unable to unlock wallet.');
        }
      }
    }
    final plain = await _storage.read(key: _mnemonicKey);
    if (plain == null) throw const WalletFailure('Wallet not found.');
    await encryptMnemonic(pin, pinSalt);
    return plain;
  }

  Future<String> unlockWithDeviceKey() async {
    final mnemonic = await _decryptDevice();
    if (mnemonic == null) {
      throw const AuthenticationFailure(
        'Enter your PIN once. Biometrics work after that.',
      );
    }
    return mnemonic;
  }

  Future<bool> hasMnemonic() async {
    try {
      return await _storage.read(key: _mnemonicKey) != null ||
          await _storage.read(key: _mnemonicEncKey) != null ||
          await _storage.read(key: _mnemonicDeviceKey) != null;
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

  Future<String> readMnemonicUnlocked(String? sessionMnemonic) async {
    if (sessionMnemonic != null && sessionMnemonic.isNotEmpty) {
      return sessionMnemonic;
    }
    throw const AuthenticationFailure('Wallet is locked.');
  }

  Future<EthPrivateKey> loadCredentials(String? sessionMnemonic) async =>
      HdWallet.credentialsAsync(await readMnemonicUnlocked(sessionMnemonic));

  Future<void> clear() async {
    try {
      await _storage.delete(key: _mnemonicKey);
      await _storage.delete(key: _mnemonicEncKey);
      await _storage.delete(key: _mnemonicDeviceKey);
      await _storage.delete(key: _deviceKey);
      await _storage.delete(key: _metaKey);
    } catch (_) {
      throw const StorageFailure('Unable to delete wallet.');
    }
  }
}
