import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class GenerateMnemonic {
  const GenerateMnemonic(this._repository);

  final WalletRepository _repository;

  String call() => _repository.generateMnemonic();
}

class CreateWallet {
  const CreateWallet(this._repository);

  final WalletRepository _repository;

  Future<Wallet> call(String mnemonic, String networkId) =>
      _repository.createWallet(mnemonic, networkId);
}
