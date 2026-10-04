import '../entities/wallet_transaction.dart';

abstract class TransactionRepository {
  List<WalletTransaction>? getCachedTransactions(String address);

  Future<List<WalletTransaction>> getTransactions(String address);

  Future<WalletTransaction?> getTransaction(String address, String hash);

  Future<FeeEstimate> estimateFee({
    required String from,
    required String to,
    required BigInt amount,
  });

  Future<WalletTransaction> sendTransaction(SendRequest request);

  Future<TxStatus> trackTransaction(String address, String hash);

  Future<void> markDropped(String address, String hash);
}
