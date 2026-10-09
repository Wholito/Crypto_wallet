import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/security/authorization_token.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

enum SessionStatus { noWallet, locked, unlocked }

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    AuthLocalDataSource(ref.watch(secureStorageProvider), LocalAuthentication()),
  ),
);

final setupPinProvider =
    Provider((ref) => SetupPin(ref.watch(authRepositoryProvider)));
final verifyPinProvider =
    Provider((ref) => VerifyPin(ref.watch(authRepositoryProvider)));
final enableBiometricProvider =
    Provider((ref) => EnableBiometric(ref.watch(authRepositoryProvider)));
final authenticateBiometricProvider =
    Provider((ref) => AuthenticateBiometric(ref.watch(authRepositoryProvider)));

class SessionNotifier extends AsyncNotifier<SessionStatus> {
  String? _mnemonic;

  String? get unlockedMnemonic => _mnemonic;

  @override
  Future<SessionStatus> build() async {
    final wallet = await ref.read(getWalletProvider)();
    final hasPin = await ref.read(authRepositoryProvider).hasPin();
    final hasMnemonic = await ref.read(walletRepositoryProvider).hasMnemonic();
    final complete = wallet != null && hasPin && hasMnemonic;
    if (!complete && (wallet != null || hasPin || hasMnemonic)) {
      await ref.read(deleteWalletProvider)();
      await ref.read(authRepositoryProvider).clear();
      await ref.read(cacheBoxProvider).clear();
      _clearSecrets();
      return SessionStatus.noWallet;
    }
    return complete ? SessionStatus.locked : SessionStatus.noWallet;
  }

  void _clearSecrets() {
    _mnemonic = null;
    AuthorizationToken.invalidateAll();
  }

  Future<AuthorizationToken> authorizeWithPin(String pin) async {
    await ref.read(verifyPinProvider)(pin);
    final salt = await ref.read(authRepositoryProvider).readPinSalt();
    if (salt == null) {
      throw StateError('PIN salt missing');
    }
    _mnemonic =
        await ref.read(walletRepositoryProvider).unlockWithPin(pin, salt);
    return AuthorizationToken.issue();
  }

  Future<void> unlockWithPin(String pin) async {
    await authorizeWithPin(pin);
    state = const AsyncData(SessionStatus.unlocked);
  }

  Future<AuthorizationToken?> authorizeWithBiometrics(String reason) async {
    final ok = await ref.read(authenticateBiometricProvider)(reason);
    if (!ok) return null;
    _mnemonic ??=
        await ref.read(walletRepositoryProvider).unlockWithDeviceKey();
    return AuthorizationToken.issue();
  }

  Future<bool> unlockWithBiometrics() async {
    final token = await authorizeWithBiometrics('Unlock wallet');
    if (token == null) return false;
    state = const AsyncData(SessionStatus.unlocked);
    return true;
  }

  void lock() {
    _clearSecrets();
    if (state.value == SessionStatus.unlocked) {
      state = const AsyncData(SessionStatus.locked);
    }
  }

  Future<void> markUnlocked(String pin) async {
    final salt = await ref.read(authRepositoryProvider).readPinSalt();
    if (salt != null) {
      await ref.read(walletRepositoryProvider).protectWithPin(pin, salt);
      _mnemonic =
          await ref.read(walletRepositoryProvider).unlockWithPin(pin, salt);
    }
    state = const AsyncData(SessionStatus.unlocked);
  }

  void markNoWallet() {
    _clearSecrets();
    state = const AsyncData(SessionStatus.noWallet);
  }
}

final sessionProvider =
    AsyncNotifierProvider<SessionNotifier, SessionStatus>(SessionNotifier.new);
