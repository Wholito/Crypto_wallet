import '../../../../core/errors/failures.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class GetWallet {
  const GetWallet(this._repository);

  final WalletRepository _repository;

  Future<Wallet?> call() => _repository.getWallet();
}

class GetWalletAddress {
  const GetWalletAddress(this._repository);

  final WalletRepository _repository;

  Future<String> call() async {
    final wallet = await _repository.getWallet();
    if (wallet == null) throw const WalletFailure('Wallet not found.');
    return wallet.address;
  }
}
