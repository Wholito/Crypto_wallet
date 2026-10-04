import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

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
      return SessionStatus.noWallet;
    }
    return complete ? SessionStatus.locked : SessionStatus.noWallet;
  }

  Future<void> unlockWithPin(String pin) async {
    await ref.read(verifyPinProvider)(pin);
    state = const AsyncData(SessionStatus.unlocked);
  }

  Future<bool> unlockWithBiometrics() async {
    final ok = await ref.read(authenticateBiometricProvider)('Unlock wallet');
    if (ok) state = const AsyncData(SessionStatus.unlocked);
    return ok;
  }

  void lock() {
    if (state.value == SessionStatus.unlocked) {
      state = const AsyncData(SessionStatus.locked);
    }
  }

  void markUnlocked() => state = const AsyncData(SessionStatus.unlocked);

  void markNoWallet() => state = const AsyncData(SessionStatus.noWallet);
}

final sessionProvider =
    AsyncNotifierProvider<SessionNotifier, SessionStatus>(SessionNotifier.new);
