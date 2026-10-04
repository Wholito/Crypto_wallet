import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';

final biometricAvailableProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(authRepositoryProvider).isBiometricAvailable(),
);

final biometricEnabledProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(authRepositoryProvider).isBiometricEnabled(),
);
