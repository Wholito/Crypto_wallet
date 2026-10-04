import 'package:web3dart/web3dart.dart';

import '../errors/failures.dart';

abstract final class Validators {
  static final _address = RegExp(r'^0x[0-9a-fA-F]{40}$');

  static bool isValidAddress(String value) {
    final text = value.trim();
    if (!_address.hasMatch(text)) return false;
    final body = text.substring(2);
    if (body == body.toLowerCase() || body == body.toUpperCase()) return true;
    try {
      EthereumAddress.fromHex(text, enforceEip55: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String requireAddress(String value) {
    final text = value.trim();
    if (!isValidAddress(text)) throw const InvalidAddressFailure();
    return text;
  }

  static bool isValidPin(String value, int length) =>
      value.length == length && RegExp(r'^\d+$').hasMatch(value);
}
