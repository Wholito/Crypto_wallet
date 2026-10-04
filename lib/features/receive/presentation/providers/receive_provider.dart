import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/usecases/receive_usecases.dart';

final getReceiveAddressProvider = Provider(
  (ref) => GetReceiveAddress(ref.watch(getWalletAddressProvider)),
);

final generateQrCodeProvider = Provider((ref) => const GenerateQrCode());

final receiveAddressProvider = FutureProvider<String>(
  (ref) => ref.watch(getReceiveAddressProvider)(),
);
