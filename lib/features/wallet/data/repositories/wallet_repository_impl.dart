import '../../../../core/errors/failures.dart';
import '../../../../core/security/hd_wallet.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_local_datasource.dart';
import '../models/wallet_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._local);

  final WalletLocalDataSource _local;

  @override
  String generateMnemonic() => HdWallet.generateMnemonic();

  @override
  bool validateMnemonic(String mnemonic) => HdWallet.validateMnemonic(mnemonic);

  @override
  Future<Wallet> createWallet(String mnemonic, String networkId) =>
      _store(mnemonic, networkId);

  @override
  Future<Wallet> restoreWallet(String mnemonic, String networkId) =>
      _store(mnemonic, networkId);

  Future<Wallet> _store(String mnemonic, String networkId) async {
    if (!HdWallet.validateMnemonic(mnemonic)) {
      throw const WalletFailure('Invalid seed phrase.');
    }
    final normalized = HdWallet.normalize(mnemonic);
    final address = await HdWallet.addressOfAsync(normalized);
    final wallet = WalletModel(
      id: address.toLowerCase(),
      address: address,
      network: networkId,
      createdAt: DateTime.now(),
    );
    await _local.save(normalized, wallet);
    final saved = await _local.readMeta();
    if (saved == null || saved.address != address) {
      throw const StorageFailure('Wallet verification failed.');
    }
    return saved;
  }

  @override
  Future<Wallet?> getWallet() => _local.readMeta();

  @override
  Future<bool> hasMnemonic() => _local.hasMnemonic();

  @override
  Future<void> protectWithPin(String pin, String pinSalt) =>
      _local.encryptMnemonic(pin, pinSalt);

  @override
  Future<String> unlockWithPin(String pin, String pinSalt) =>
      _local.unlockWithPin(pin, pinSalt);

  @override
  Future<String> unlockWithDeviceKey() => _local.unlockWithDeviceKey();

  @override
  Future<String> exportMnemonic(String sessionMnemonic) =>
      _local.readMnemonicUnlocked(sessionMnemonic);

  @override
  Future<void> deleteWallet() => _local.clear();
}
