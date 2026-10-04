import 'dart:isolate';
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:web3dart/web3dart.dart';

import '../constants/app_constants.dart';

abstract final class HdWallet {
  static String generateMnemonic() => bip39.generateMnemonic();

  static String normalize(String mnemonic) =>
      mnemonic.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');

  static bool validateMnemonic(String mnemonic) =>
      bip39.validateMnemonic(normalize(mnemonic));

  static Uint8List derivePrivateKey(String mnemonic, {int index = 0}) {
    final seed = bip39.mnemonicToSeed(normalize(mnemonic));
    final root = bip32.BIP32.fromSeed(seed);
    final path =
        AppConstants.derivationPath.replaceFirst(RegExp(r'0$'), '$index');
    final key = root.derivePath(path).privateKey;
    if (key == null) {
      throw StateError('Key derivation failed');
    }
    return key;
  }

  static Future<Uint8List> derivePrivateKeyAsync(String mnemonic,
          {int index = 0}) =>
      Isolate.run(() => derivePrivateKey(mnemonic, index: index));

  static EthPrivateKey credentials(String mnemonic, {int index = 0}) =>
      EthPrivateKey(derivePrivateKey(mnemonic, index: index));

  static Future<EthPrivateKey> credentialsAsync(String mnemonic,
          {int index = 0}) async =>
      EthPrivateKey(await derivePrivateKeyAsync(mnemonic, index: index));

  static String addressOf(String mnemonic, {int index = 0}) =>
      credentials(mnemonic, index: index).address.hexEip55;

  static Future<String> addressOfAsync(String mnemonic, {int index = 0}) async =>
      (await credentialsAsync(mnemonic, index: index)).address.hexEip55;
}
