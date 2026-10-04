import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/validators.dart';
import '../repositories/auth_repository.dart';

class SetupPin {
  const SetupPin(this._repository);

  final AuthRepository _repository;

  Future<void> call(String pin) {
    if (!Validators.isValidPin(pin, AppConstants.pinLength)) {
      throw const AuthenticationFailure('PIN must contain 6 digits.');
    }
    return _repository.setPin(pin);
  }
}

class VerifyPin {
  const VerifyPin(this._repository);

  final AuthRepository _repository;

  Future<void> call(String pin) => _repository.verifyPin(pin);
}

class EnableBiometric {
  const EnableBiometric(this._repository);

  final AuthRepository _repository;

  Future<void> call(bool enabled) async {
    if (enabled) {
      if (!await _repository.isBiometricAvailable()) {
        throw const AuthenticationFailure('Biometrics are not available.');
      }
      final ok = await _repository
          .authenticateWithBiometrics('Enable biometric unlock');
      if (!ok) throw const AuthenticationFailure();
    }
    await _repository.setBiometricEnabled(enabled);
  }
}

class AuthenticateBiometric {
  const AuthenticateBiometric(this._repository);

  final AuthRepository _repository;

  Future<bool> call(String reason) async {
    if (!await _repository.isBiometricEnabled()) return false;
    if (!await _repository.isBiometricAvailable()) return false;
    return _repository.authenticateWithBiometrics(reason);
  }
}
