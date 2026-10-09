import '../entities/asset.dart';

abstract class AssetsRepository {
  List<Asset>? getCachedAssets(String address);

  Future<Asset> getNativeAsset(String address);

  Future<List<Asset>> getAssets(String address);

  Future<BigInt> getTokenBalance(String address, String contract);
}
