import 'package:crypto_wallet/features/transactions/data/models/transaction_model.dart';
import 'package:crypto_wallet/features/transactions/domain/entities/wallet_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const owner = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';

  Map<String, dynamic> row({String isError = '0', String block = '100'}) => {
        'hash': '0xabc',
        'from': '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
        'to': owner,
        'value': '1000000000000000000',
        'gasUsed': '21000',
        'gasPrice': '1000000000',
        'timeStamp': '1700000000',
        'isError': isError,
        'txreceipt_status': isError == '1' ? '0' : '1',
        'blockNumber': block,
      };

  test('parses received confirmed transaction', () {
    final tx = TransactionModel.fromExplorer(
      row(),
      owner: owner,
      symbol: 'ETH',
      decimals: 18,
    );
    expect(tx.type, TxType.received);
    expect(tx.status, TxStatus.confirmed);
    expect(tx.amount, BigInt.parse('1000000000000000000'));
    expect(tx.fee, BigInt.zero);
    expect(tx.timestamp.millisecondsSinceEpoch, 1700000000000);
  });

  test('marks contract calls and pending timestamp', () {
    final tx = TransactionModel.fromExplorer(
      {
        'hash': '0xdef',
        'from': owner,
        'to': '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
        'value': '0',
        'input': '0xa9059cbb',
        'gasUsed': '50000',
        'gasPrice': '1000000000',
        'timeStamp': '0',
        'isError': '0',
        'txreceipt_status': '1',
        'blockNumber': '0',
      },
      owner: owner,
      symbol: 'ETH',
      decimals: 18,
    );
    expect(tx.isContractCall, isTrue);
    expect(tx.asset, 'Contract');
    expect(tx.status, TxStatus.pending);
    expect(tx.timestamp.millisecondsSinceEpoch, greaterThan(0));
  });

  test('parses failed transaction', () {
    final tx = TransactionModel.fromExplorer(
      row(isError: '1'),
      owner: owner,
      symbol: 'ETH',
      decimals: 18,
    );
    expect(tx.status, TxStatus.failed);
  });

  test('parses pending transaction', () {
    final tx = TransactionModel.fromExplorer(
      row(block: '0'),
      owner: owner,
      symbol: 'ETH',
      decimals: 18,
    );
    expect(tx.status, TxStatus.pending);
  });

  test('json round trip', () {
    final tx = TransactionModel.fromExplorer(
      row(),
      owner: owner,
      symbol: 'ETH',
      decimals: 18,
    );
    final copy = TransactionModel.fromJson(TransactionModel.toJson(tx));
    expect(copy, tx);
    expect(copy.amount, tx.amount);
    expect(copy.type, tx.type);
  });
}
