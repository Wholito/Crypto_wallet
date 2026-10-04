import '../../domain/entities/wallet_transaction.dart';

class TransactionModel {
  static WalletTransaction fromExplorer(
    Map<String, dynamic> json, {
    required String owner,
    required String symbol,
    required int decimals,
  }) {
    final from = (json['from'] as String? ?? '');
    final to = (json['to'] as String? ?? '');
    final failed = json['isError'] == '1' || json['txreceipt_status'] == '0';
    final confirmed = (json['blockNumber'] as String? ?? '0') != '0';
    final gasUsed = BigInt.tryParse('${json['gasUsed'] ?? 0}') ?? BigInt.zero;
    final gasPrice = BigInt.tryParse('${json['gasPrice'] ?? 0}') ?? BigInt.zero;
    final seconds = int.tryParse('${json['timeStamp'] ?? 0}') ?? 0;
    final amount = BigInt.tryParse('${json['value'] ?? 0}') ?? BigInt.zero;
    final input = (json['input'] as String? ?? '0x').toLowerCase();
    final isContractCall =
        amount == BigInt.zero && input.isNotEmpty && input != '0x';
    final type = from.toLowerCase() == owner.toLowerCase()
        ? TxType.sent
        : TxType.received;
    final status = failed
        ? TxStatus.failed
        : confirmed
            ? TxStatus.confirmed
            : TxStatus.pending;
    final timestamp = seconds > 0
        ? DateTime.fromMillisecondsSinceEpoch(seconds * 1000)
        : DateTime.now();
    return WalletTransaction(
      hash: json['hash'] as String,
      from: from,
      to: to,
      amount: amount,
      asset: isContractCall ? 'Contract' : symbol,
      decimals: decimals,
      fee: type == TxType.sent ? gasUsed * gasPrice : BigInt.zero,
      status: status,
      timestamp: timestamp,
      type: type,
      isContractCall: isContractCall,
    );
  }

  static Map<String, dynamic> toJson(WalletTransaction tx) => {
        'hash': tx.hash,
        'from': tx.from,
        'to': tx.to,
        'amount': tx.amount.toString(),
        'asset': tx.asset,
        'decimals': tx.decimals,
        'fee': tx.fee.toString(),
        'status': tx.status.name,
        'timestamp': tx.timestamp.millisecondsSinceEpoch,
        'type': tx.type.name,
        'isContractCall': tx.isContractCall,
      };

  static WalletTransaction fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        hash: json['hash'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        amount: BigInt.parse(json['amount'] as String),
        asset: json['asset'] as String,
        decimals: json['decimals'] as int,
        fee: BigInt.parse(json['fee'] as String),
        status: TxStatus.values.byName(json['status'] as String),
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        type: TxType.values.byName(json['type'] as String),
        isContractCall: json['isContractCall'] as bool? ?? false,
      );
}
