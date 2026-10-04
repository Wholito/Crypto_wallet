import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_providers.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

class OnboardingService {
  const OnboardingService(this._ref);

  final Ref _ref;

  Future<void> createWallet(String mnemonic, String pin) async {
    final network = _ref.read(currentNetworkProvider);
    await _ref.read(createWalletProvider)(mnemonic, network.id);
    await _finish(pin);
  }

  Future<void> restoreWallet(String mnemonic, String pin) async {
    final network = _ref.read(currentNetworkProvider);
    await _ref.read(restoreWalletProvider)(mnemonic, network.id);
    await _finish(pin);
  }

  Future<void> _finish(String pin) async {
    try {
      await _ref.read(setupPinProvider)(pin);
    } catch (_) {
      await _ref.read(deleteWalletProvider)();
      rethrow;
    }
    await _ref.read(cacheBoxProvider).clear();
    _ref.invalidate(walletProvider);
    _ref.read(sessionProvider.notifier).markUnlocked();
  }

  Future<void> resetWallet() async {
    await _ref.read(deleteWalletProvider)();
    await _ref.read(authRepositoryProvider).clear();
    await _ref.read(cacheBoxProvider).clear();
    _ref.invalidate(walletProvider);
    _ref.read(sessionProvider.notifier).markNoWallet();
  }
}

final onboardingServiceProvider =
    Provider<OnboardingService>(OnboardingService.new);
