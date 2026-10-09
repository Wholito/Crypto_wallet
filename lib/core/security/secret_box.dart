import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

abstract final class SecretBox {
  static const iterations = 4096;

  static Uint8List randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  static Uint8List deriveKey(String pin, Uint8List salt) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    var block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = Uint8List.fromList(block);
    for (var i = 1; i < iterations; i++) {
      block = hmac.convert(block).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= block[j];
      }
    }
    return result;
  }

  static String seal(String plaintext, Uint8List key) {
    final nonce = randomBytes(12);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));
    final encrypted = cipher.process(Uint8List.fromList(utf8.encode(plaintext)));
    return jsonEncode({
      'v': 1,
      'nonce': base64Encode(nonce),
      'cipher': base64Encode(encrypted),
    });
  }

  static String open(String payload, Uint8List key) {
    final json = jsonDecode(payload) as Map<String, dynamic>;
    final nonce = base64Decode(json['nonce'] as String);
    final cipherBytes = base64Decode(json['cipher'] as String);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));
    return utf8.decode(cipher.process(cipherBytes));
  }

  static Future<String> sealWithPin(String plaintext, String pin, String saltB64) =>
      Isolate.run(() => _sealWithPin(plaintext, pin, saltB64));

  static Future<String> openWithPin(String payload, String pin, String saltB64) =>
      Isolate.run(() => _openWithPin(payload, pin, saltB64));

  static String _sealWithPin(String plaintext, String pin, String saltB64) {
    final key = deriveKey(pin, base64Decode(saltB64));
    try {
      return seal(plaintext, key);
    } finally {
      key.fillRange(0, key.length, 0);
    }
  }

  static String _openWithPin(String payload, String pin, String saltB64) {
    final key = deriveKey(pin, base64Decode(saltB64));
    try {
      return open(payload, key);
    } finally {
      key.fillRange(0, key.length, 0);
    }
  }
}
