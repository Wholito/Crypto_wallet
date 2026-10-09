import '../entities/asset.dart';
import '../repositories/assets_repository.dart';

class GetBalance {
  const GetBalance(this._repository);

  final AssetsRepository _repository;

  Future<BigInt> call(String address) async =>
      (await _repository.getNativeAsset(address)).balance;
}

class GetTokenBalance {
  const GetTokenBalance(this._repository);

  final AssetsRepository _repository;

  Future<BigInt> call(String address, String contract) =>
      _repository.getTokenBalance(address, contract);
}

class GetAssets {
  const GetAssets(this._repository);

  final AssetsRepository _repository;

  List<Asset>? cached(String address) => _repository.getCachedAssets(address);

  Future<List<Asset>> call(String address) => _repository.getAssets(address);
}
