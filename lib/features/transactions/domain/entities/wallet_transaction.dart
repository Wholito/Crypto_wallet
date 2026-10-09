import 'package:equatable/equatable.dart';

enum TxStatus { pending, confirmed, failed, dropped }

enum TxType { sent, received }

class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.hash,
    required this.from,
    required this.to,
    required this.amount,
    required this.asset,
    required this.decimals,
    required this.fee,
    required this.status,
    required this.timestamp,
    required this.type,
    this.isContractCall = false,
  });

  final String hash;
  final String from;
  final String to;
  final BigInt amount;
  final String asset;
  final int decimals;
  final BigInt fee;
  final TxStatus status;
  final DateTime timestamp;
  final TxType type;
  final bool isContractCall;

  WalletTransaction copyWith({
    TxStatus? status,
    DateTime? timestamp,
    BigInt? fee,
    bool? isContractCall,
  }) =>
      WalletTransaction(
        hash: hash,
        from: from,
        to: to,
        amount: amount,
        asset: asset,
        decimals: decimals,
        fee: fee ?? this.fee,
        status: status ?? this.status,
        timestamp: timestamp ?? this.timestamp,
        type: type,
        isContractCall: isContractCall ?? this.isContractCall,
      );

  @override
  List<Object?> get props => [hash, status, isContractCall];
}

class FeeEstimate extends Equatable {
  const FeeEstimate({
    required this.gasLimit,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
  });

  final BigInt gasLimit;
  final BigInt maxFeePerGas;
  final BigInt maxPriorityFeePerGas;

  BigInt get fee => gasLimit * maxFeePerGas;

  BigInt get gasPrice => maxFeePerGas;

  @override
  List<Object?> get props => [gasLimit, maxFeePerGas, maxPriorityFeePerGas];
}

class SendRequest extends Equatable {
  const SendRequest({
    required this.to,
    required this.amount,
    required this.estimate,
    required this.asset,
    required this.decimals,
    this.tokenContract,
    this.warning,
  });

  final String to;
  final BigInt amount;
  final FeeEstimate estimate;
  final String asset;
  final int decimals;
  final String? tokenContract;
  final String? warning;

  bool get isToken => tokenContract != null;

  SendRequest copyWith({FeeEstimate? estimate, String? warning}) => SendRequest(
        to: to,
        amount: amount,
        estimate: estimate ?? this.estimate,
        asset: asset,
        decimals: decimals,
        tokenContract: tokenContract,
        warning: warning ?? this.warning,
      );

  @override
  List<Object?> get props =>
      [to, amount, estimate, asset, decimals, tokenContract, warning];
}
