import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._local);

  final AuthLocalDataSource _local;

  @override
  Future<bool> hasPin() => _local.hasPin();

  @override
  Future<void> setPin(String pin) => _local.setPin(pin);

  @override
  Future<void> verifyPin(String pin) => _local.verifyPin(pin);

  @override
  Future<bool> isBiometricAvailable() => _local.isBiometricAvailable();

  @override
  Future<bool> isBiometricEnabled() => _local.isBiometricEnabled();

  @override
  Future<void> setBiometricEnabled(bool enabled) =>
      _local.setBiometricEnabled(enabled);

  @override
  Future<bool> authenticateWithBiometrics(String reason) =>
      _local.authenticate(reason);

  @override
  Future<void> clear() => _local.clear();
}
