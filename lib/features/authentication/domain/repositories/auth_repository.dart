abstract class AuthRepository {
  Future<bool> hasPin();

  Future<void> setPin(String pin);

  Future<void> verifyPin(String pin);

  Future<String?> readPinSalt();

  Future<bool> isBiometricAvailable();

  Future<bool> isBiometricEnabled();

  Future<void> setBiometricEnabled(bool enabled);

  Future<bool> authenticateWithBiometrics(String reason);

  Future<void> clear();
}
