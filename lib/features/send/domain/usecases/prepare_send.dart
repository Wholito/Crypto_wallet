import '../../../../core/errors/failures.dart';
import '../../../../core/utils/units.dart';
import '../../../../core/utils/validators.dart';
import '../../../assets/domain/usecases/assets_usecases.dart';
import '../../../transactions/domain/entities/wallet_transaction.dart';
import '../../../transactions/domain/usecases/transaction_usecases.dart';

class PrepareSend {
  const PrepareSend(this._getBalance, this._estimateGas);

  final GetBalance _getBalance;
  final EstimateGas _estimateGas;

  Future<SendRequest> call({
    required String from,
    required String to,
    required String amountText,
    required int decimals,
  }) async {
    final recipient = Validators.requireAddress(to);
    final amount = Units.parse(amountText, decimals);
    if (amount <= BigInt.zero) {
      throw const InvalidAmountFailure('Amount must be greater than zero.');
    }
    final balance = await _getBalance(from);
    if (amount > balance) throw const InsufficientBalanceFailure();
    final estimate =
        await _estimateGas(from: from, to: recipient, amount: amount);
    if (amount + estimate.fee > balance) {
      throw const InsufficientBalanceFailure(
        'Insufficient balance to cover the amount and network fee.',
      );
    }
    return SendRequest(to: recipient, amount: amount, estimate: estimate);
  }
}
