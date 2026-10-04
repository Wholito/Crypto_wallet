import '../../../wallet/domain/usecases/get_wallet_address.dart';

class GetReceiveAddress {
  const GetReceiveAddress(this._getAddress);

  final GetWalletAddress _getAddress;

  Future<String> call() => _getAddress();
}

class GenerateQrCode {
  const GenerateQrCode();

  String call(String address) => address;
}
