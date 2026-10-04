import '../entities/wallet.dart';

abstract class WalletRepository {
  String generateMnemonic();

  bool validateMnemonic(String mnemonic);

  Future<Wallet> createWallet(String mnemonic, String networkId);

  Future<Wallet> restoreWallet(String mnemonic, String networkId);

  Future<Wallet?> getWallet();

  Future<bool> hasMnemonic();

  Future<String> exportMnemonic();

  Future<void> deleteWallet();
}
