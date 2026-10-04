import '../repositories/wallet_repository.dart';

class ExportWallet {
  const ExportWallet(this._repository);

  final WalletRepository _repository;

  Future<String> call() => _repository.exportMnemonic();
}

class DeleteWallet {
  const DeleteWallet(this._repository);

  final WalletRepository _repository;

  Future<void> call() => _repository.deleteWallet();
}
