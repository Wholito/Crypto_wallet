import 'package:crypto_wallet/core/constants/networks.dart';
import 'package:crypto_wallet/core/errors/failures.dart';
import 'package:crypto_wallet/core/security/hd_wallet.dart';
import 'package:crypto_wallet/core/security/pin_policy.dart';
import 'package:crypto_wallet/core/storage/storage_providers.dart';
import 'package:crypto_wallet/features/assets/domain/entities/asset.dart';
import 'package:crypto_wallet/features/assets/domain/repositories/assets_repository.dart';
import 'package:crypto_wallet/features/assets/presentation/providers/assets_provider.dart';
import 'package:crypto_wallet/features/authentication/domain/repositories/auth_repository.dart';
import 'package:crypto_wallet/features/authentication/presentation/providers/auth_provider.dart';
import 'package:crypto_wallet/features/settings/domain/entities/app_settings.dart';
import 'package:crypto_wallet/features/settings/domain/repositories/settings_repository.dart';
import 'package:crypto_wallet/features/settings/presentation/providers/settings_provider.dart';
import 'package:crypto_wallet/features/transactions/domain/entities/wallet_transaction.dart';
import 'package:crypto_wallet/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:crypto_wallet/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:crypto_wallet/features/wallet/domain/entities/wallet.dart';
import 'package:crypto_wallet/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:crypto_wallet/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:crypto_wallet/shared/models/network.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<String> {}

class FakeWalletRepository implements WalletRepository {
  String? _mnemonic;
  Wallet? _wallet;

  @override
  String generateMnemonic() => HdWallet.generateMnemonic();

  @override
  bool validateMnemonic(String mnemonic) => HdWallet.validateMnemonic(mnemonic);

  @override
  Future<Wallet> createWallet(String mnemonic, String networkId) async {
    _mnemonic = HdWallet.normalize(mnemonic);
    return _wallet = Wallet(
      id: 'id',
      address: HdWallet.addressOf(_mnemonic!),
      network: networkId,
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<Wallet> restoreWallet(String mnemonic, String networkId) =>
      createWallet(mnemonic, networkId);

  @override
  Future<Wallet?> getWallet() async => _wallet;

  @override
  Future<bool> hasMnemonic() async => _mnemonic != null;

  @override
  Future<void> protectWithPin(String pin, String pinSalt) async {}

  @override
  Future<String> unlockWithPin(String pin, String pinSalt) async => _mnemonic!;

  @override
  Future<String> unlockWithDeviceKey() async => _mnemonic!;

  @override
  Future<String> exportMnemonic(String sessionMnemonic) async =>
      sessionMnemonic.isNotEmpty ? sessionMnemonic : _mnemonic!;

  @override
  Future<void> deleteWallet() async {
    _wallet = null;
    _mnemonic = null;
  }
}

class FakeAuthRepository implements AuthRepository {
  String? pin;
  String salt = 'dGVzdC1zYWx0LXZhbHVlLTE2';
  bool biometricEnabled = false;

  @override
  Future<bool> hasPin() async => pin != null;

  @override
  Future<void> setPin(String value) async {
    if (PinPolicy.isTrivial(value)) {
      throw const AuthenticationFailure(
        'PIN is too simple. Avoid sequences and repeated digits.',
      );
    }
    pin = value;
  }

  @override
  Future<void> verifyPin(String value) async {
    if (value != pin) throw const AuthenticationFailure('Wrong PIN.');
  }

  @override
  Future<String?> readPinSalt() async => salt;

  @override
  Future<bool> isBiometricAvailable() async => false;

  @override
  Future<bool> isBiometricEnabled() async => biometricEnabled;

  @override
  Future<void> setBiometricEnabled(bool enabled) async =>
      biometricEnabled = enabled;

  @override
  Future<bool> authenticateWithBiometrics(String reason) async => false;

  @override
  Future<void> clear() async => pin = null;
}

class FakeSettingsRepository implements SettingsRepository {
  AppSettings settings = const AppSettings(network: Networks.sepolia);

  @override
  AppSettings load() => settings;

  @override
  Future<void> saveNetwork(Network network) async =>
      settings = settings.copyWith(network: network);

  @override
  Future<void> saveTheme(AppThemeMode theme) async =>
      settings = settings.copyWith(theme: theme);

  @override
  Future<void> saveCurrency(String currency) async =>
      settings = settings.copyWith(currency: currency);
}

class FakeAssetsRepository implements AssetsRepository {
  FakeAssetsRepository(this.balance);

  BigInt balance;

  Asset _asset() => Asset(
        id: 'native',
        symbol: 'SepoliaETH',
        name: 'Sepolia Ether',
        decimals: 18,
        balance: balance,
      );

  @override
  List<Asset>? getCachedAssets(String address) => null;

  @override
  Future<Asset> getNativeAsset(String address) async => _asset();

  @override
  Future<List<Asset>> getAssets(String address) async => [_asset()];

  @override
  Future<BigInt> getTokenBalance(String address, String contract) async =>
      balance;
}

class FakeTransactionRepository implements TransactionRepository {
  final List<WalletTransaction> sent = [];

  @override
  List<WalletTransaction>? getCachedTransactions(String address) => null;

  @override
  Future<List<WalletTransaction>> getTransactions(String address) async =>
      List.of(sent);

  @override
  Future<WalletTransaction?> getTransaction(String address, String hash) async =>
      sent.where((t) => t.hash == hash).firstOrNull;

  @override
  Future<FeeEstimate> estimateFee({
    required String from,
    required String to,
    required BigInt amount,
    String? tokenContract,
  }) async =>
      FeeEstimate(
        gasLimit: BigInt.from(21000),
        maxFeePerGas: BigInt.from(1000000000),
        maxPriorityFeePerGas: BigInt.from(1000000000),
      );

  @override
  Future<bool> isContractAddress(String address) async => false;

  @override
  Future<WalletTransaction> sendTransaction(
    SendRequest request,
    String sessionMnemonic,
  ) async {
    final tx = WalletTransaction(
      hash: '0x${'ab' * 32}',
      from: 'from',
      to: request.to,
      amount: request.amount,
      asset: request.asset,
      decimals: request.decimals,
      fee: request.estimate.fee,
      status: TxStatus.pending,
      timestamp: DateTime(2026),
      type: TxType.sent,
      isContractCall: request.isToken,
    );
    sent.add(tx);
    return tx;
  }

  @override
  Future<TxStatus> trackTransaction(String address, String hash) async =>
      TxStatus.pending;

  @override
  Future<void> markDropped(String address, String hash) async {}
}

List<Override> fakeOverrides({
  FakeWalletRepository? wallet,
  FakeAuthRepository? auth,
  FakeSettingsRepository? settings,
  FakeAssetsRepository? assets,
  FakeTransactionRepository? transactions,
}) {
  final box = MockBox();
  when(box.clear).thenAnswer((_) async => 0);
  return [
    walletRepositoryProvider.overrideWithValue(wallet ?? FakeWalletRepository()),
    authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
    settingsRepositoryProvider
        .overrideWithValue(settings ?? FakeSettingsRepository()),
    assetsRepositoryProvider.overrideWithValue(
      assets ?? FakeAssetsRepository(BigInt.parse('1500000000000000000')),
    ),
    transactionRepositoryProvider
        .overrideWithValue(transactions ?? FakeTransactionRepository()),
    cacheBoxProvider.overrideWithValue(box),
  ];
}
