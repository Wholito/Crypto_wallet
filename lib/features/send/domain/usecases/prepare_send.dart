import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/units.dart';
import '../../../../core/utils/validators.dart';
import '../../../assets/domain/usecases/assets_usecases.dart';
import '../../../transactions/domain/entities/wallet_transaction.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../../transactions/domain/usecases/transaction_usecases.dart';

class PrepareSend {
  const PrepareSend(
    this._getBalance,
    this._getTokenBalance,
    this._estimateGas,
    this._repository,
  );

  final GetBalance _getBalance;
  final GetTokenBalance _getTokenBalance;
  final EstimateGas _estimateGas;
  final TransactionRepository _repository;

  Future<SendRequest> call({
    required String from,
    required String to,
    required String amountText,
    required int decimals,
    required String asset,
    String? tokenContract,
  }) async {
    final recipient = Validators.requireAddress(to);
    if (recipient.toLowerCase() == AppConstants.zeroAddress) {
      throw const InvalidAddressFailure('Cannot send to the zero address.');
    }
    if (tokenContract != null &&
        recipient.toLowerCase() == tokenContract.toLowerCase()) {
      throw const InvalidAddressFailure(
        'Cannot send tokens to the token contract address.',
      );
    }
    final amount = Units.parse(amountText, decimals);
    if (amount <= BigInt.zero) {
      throw const InvalidAmountFailure('Amount must be greater than zero.');
    }
    final nativeBalance = await _getBalance(from);
    final spendable = tokenContract == null
        ? nativeBalance
        : await _getTokenBalance(from, tokenContract);
    if (amount > spendable) throw const InsufficientBalanceFailure();
    final estimate = await _estimateGas(
      from: from,
      to: recipient,
      amount: amount,
      tokenContract: tokenContract,
    );
    if (tokenContract == null) {
      if (amount + estimate.fee > nativeBalance) {
        throw const InsufficientBalanceFailure(
          'Insufficient balance to cover the amount and network fee.',
        );
      }
    } else if (estimate.fee > nativeBalance) {
      throw const InsufficientBalanceFailure(
        'Insufficient native balance to cover the network fee.',
      );
    }
    final warning = await _warning(from, recipient);
    return SendRequest(
      to: recipient,
      amount: amount,
      estimate: estimate,
      asset: asset,
      decimals: decimals,
      tokenContract: tokenContract,
      warning: warning,
    );
  }

  Future<BigInt> maxSendable({
    required String from,
    required String to,
    required int decimals,
    String? tokenContract,
  }) async {
    final recipient = Validators.requireAddress(to);
    if (tokenContract != null) {
      final tokenBalance = await _getTokenBalance(from, tokenContract);
      if (tokenBalance <= BigInt.zero) return BigInt.zero;
      final nativeBalance = await _getBalance(from);
      final estimate = await _estimateGas(
        from: from,
        to: recipient,
        amount: tokenBalance,
        tokenContract: tokenContract,
      );
      if (estimate.fee > nativeBalance) return BigInt.zero;
      return tokenBalance;
    }
    final balance = await _getBalance(from);
    final probe = balance > BigInt.zero ? BigInt.one : BigInt.zero;
    if (probe == BigInt.zero) return BigInt.zero;
    final estimate = await _estimateGas(
      from: from,
      to: recipient,
      amount: probe,
    );
    final max = balance - estimate.fee;
    return max > BigInt.zero ? max : BigInt.zero;
  }

  Future<String?> _warning(String from, String to) async {
    if (from.toLowerCase() == to.toLowerCase()) {
      return 'You are sending to your own address.';
    }
    try {
      if (await _repository.isContractAddress(to)) {
        return 'Recipient looks like a smart contract.';
      }
    } catch (_) {}
    return null;
  }
}
