import '../entities/wallet_transaction.dart';
import '../repositories/transaction_repository.dart';

class GetTransactions {
  const GetTransactions(this._repository);

  final TransactionRepository _repository;

  List<WalletTransaction>? cached(String address) =>
      _repository.getCachedTransactions(address);

  Future<List<WalletTransaction>> call(String address) =>
      _repository.getTransactions(address);
}

class GetTransaction {
  const GetTransaction(this._repository);

  final TransactionRepository _repository;

  Future<WalletTransaction?> call(String address, String hash) =>
      _repository.getTransaction(address, hash);
}

class EstimateGas {
  const EstimateGas(this._repository);

  final TransactionRepository _repository;

  Future<FeeEstimate> call({
    required String from,
    required String to,
    required BigInt amount,
  }) =>
      _repository.estimateFee(from: from, to: to, amount: amount);
}

class SendTransaction {
  const SendTransaction(this._repository);

  final TransactionRepository _repository;

  Future<WalletTransaction> call(SendRequest request) =>
      _repository.sendTransaction(request);
}

class TrackTransaction {
  const TrackTransaction(this._repository);

  final TransactionRepository _repository;

  Future<TxStatus> call(String address, String hash) =>
      _repository.trackTransaction(address, hash);
}
