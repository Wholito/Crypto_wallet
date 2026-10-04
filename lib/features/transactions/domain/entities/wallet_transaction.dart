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
  const FeeEstimate({required this.gasLimit, required this.gasPrice});

  final BigInt gasLimit;
  final BigInt gasPrice;

  BigInt get fee => gasLimit * gasPrice;

  @override
  List<Object?> get props => [gasLimit, gasPrice];
}

class SendRequest extends Equatable {
  const SendRequest({
    required this.to,
    required this.amount,
    required this.estimate,
  });

  final String to;
  final BigInt amount;
  final FeeEstimate estimate;

  @override
  List<Object?> get props => [to, amount, estimate];
}
