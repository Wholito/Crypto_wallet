import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/security/pin_hasher.dart';
import '../../../../core/security/pin_policy.dart';
import '../../../../core/utils/mono_clock.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._storage, this._localAuth);

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  static const _hashKey = 'pin_hash';
  static const _saltKey = 'pin_salt';
  static const _attemptsKey = 'pin_attempts';
  static const _lockKey = 'pin_lock_until';
  static const _lockLevelKey = 'pin_lock_level';
  static const _biometricKey = 'biometric_enabled';

  Future<bool> hasPin() async {
    try {
      return await _storage.read(key: _hashKey) != null;
    } catch (_) {
      throw const StorageFailure();
    }
  }

  Future<String?> readPinSalt() async {
    try {
      return await _storage.read(key: _saltKey);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  Future<void> setPin(String pin) async {
    if (PinPolicy.isTrivial(pin)) {
      throw const AuthenticationFailure(
        'PIN is too simple. Avoid sequences and repeated digits.',
      );
    }
    try {
      final salt = PinHasher.generateSalt();
      final hash = await PinHasher.hashAsync(pin, salt);
      await _storage.write(key: _saltKey, value: salt);
      await _storage.write(key: _hashKey, value: hash);
      await _resetAttempts();
    } catch (e) {
      if (e is Failure) rethrow;
      throw const StorageFailure('Unable to save PIN.');
    }
  }

  Future<void> verifyPin(String pin) async {
    final lockUntil = int.tryParse(await _storage.read(key: _lockKey) ?? '');
    final now = MonoClock.nowMs();
    final maxLockMs = AppConstants.lockoutSeconds.last * 1000;
    if (lockUntil != null) {
      final remaining = lockUntil - now;
      if (remaining > 0 && remaining <= maxLockMs * 2) {
        final seconds = (remaining / 1000).ceil();
        throw AuthenticationFailure(
          'Too many attempts. Try again in $seconds s.',
        );
      }
      if (remaining > maxLockMs * 2) {
        await _storage.delete(key: _lockKey);
      }
    }
    final hash = await _storage.read(key: _hashKey);
    final salt = await _storage.read(key: _saltKey);
    if (hash == null || salt == null) {
      throw const AuthenticationFailure('PIN is not set.');
    }
    if (await PinHasher.verifyAsync(pin, salt, hash)) {
      await _resetAttempts();
      return;
    }
    final attempts =
        (int.tryParse(await _storage.read(key: _attemptsKey) ?? '') ?? 0) + 1;
    if (attempts >= AppConstants.maxPinAttempts) {
      final level =
          int.tryParse(await _storage.read(key: _lockLevelKey) ?? '') ?? 0;
      final seconds = AppConstants.lockoutSeconds[
          level.clamp(0, AppConstants.lockoutSeconds.length - 1)];
      await _storage.write(key: _lockKey, value: '${now + seconds * 1000}');
      await _storage.write(key: _lockLevelKey, value: '${level + 1}');
      await _storage.write(key: _attemptsKey, value: '0');
      throw AuthenticationFailure(
        'Too many attempts. Try again in $seconds s.',
      );
    }
    await _storage.write(key: _attemptsKey, value: '$attempts');
    throw AuthenticationFailure(
      'Wrong PIN. ${AppConstants.maxPinAttempts - attempts} attempts left.',
    );
  }

  Future<void> _resetAttempts() async {
    await _storage.delete(key: _attemptsKey);
    await _storage.delete(key: _lockKey);
    await _storage.delete(key: _lockLevelKey);
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;
      final biometrics = await _localAuth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async =>
      await _storage.read(key: _biometricKey) == 'true';

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _biometricKey, value: '$enabled');

  Future<bool> authenticate(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _hashKey);
    await _storage.delete(key: _saltKey);
    await _storage.delete(key: _biometricKey);
    await _resetAttempts();
  }
}
