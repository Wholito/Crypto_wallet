import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

abstract final class PinHasher {
  static const iterations = 20000;

  static String generateSalt() {
    final random = Random.secure();
    return base64Encode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  static String hash(String pin, String salt, {int rounds = iterations}) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    final saltBytes = base64Decode(salt);
    var block = hmac.convert([...saltBytes, 0, 0, 0, 1]).bytes;
    final result = Uint8List.fromList(block);
    for (var i = 1; i < rounds; i++) {
      block = hmac.convert(block).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= block[j];
      }
    }
    return base64Encode(result);
  }

  static Future<String> hashAsync(String pin, String salt,
          {int rounds = iterations}) =>
      Isolate.run(() => hash(pin, salt, rounds: rounds));

  static bool verify(String pin, String salt, String expected,
      {int rounds = iterations}) {
    final actual = hash(pin, salt, rounds: rounds);
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ expected.codeUnitAt(i);
    }
    return diff == 0;
  }

  static Future<bool> verifyAsync(String pin, String salt, String expected,
          {int rounds = iterations}) =>
      Isolate.run(() => verify(pin, salt, expected, rounds: rounds));
}
