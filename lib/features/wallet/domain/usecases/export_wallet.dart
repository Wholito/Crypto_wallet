import '../../../../core/errors/failures.dart';
import '../../../../core/security/authorization_token.dart';
import '../repositories/wallet_repository.dart';

class ExportWallet {
  const ExportWallet(this._repository);

  final WalletRepository _repository;

  Future<String> call(AuthorizationToken auth, String sessionMnemonic) {
    if (!auth.isValid) {
      throw const AuthenticationFailure('Authorization required.');
    }
    auth.consume();
    return _repository.exportMnemonic(sessionMnemonic);
  }
}

class DeleteWallet {
  const DeleteWallet(this._repository);

  final WalletRepository _repository;

  Future<void> call() => _repository.deleteWallet();
}
