import '../../../../core/errors/failures.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class RestoreWallet {
  const RestoreWallet(this._repository);

  final WalletRepository _repository;

  Future<Wallet> call(String mnemonic, String networkId) {
    if (!_repository.validateMnemonic(mnemonic)) {
      throw const WalletFailure('Invalid seed phrase.');
    }
    return _repository.restoreWallet(mnemonic, networkId);
  }
}
