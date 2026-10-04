import '../errors/failures.dart';

abstract final class Units {
  static BigInt parse(String input, int decimals) {
    final text = input.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text) || text.isEmpty || text == '.') {
      throw const InvalidAmountFailure();
    }
    final parts = text.split('.');
    final whole = parts[0].isEmpty ? '0' : parts[0];
    final fraction = parts.length > 1 ? parts[1] : '';
    if (fraction.length > decimals) {
      throw InvalidAmountFailure('Maximum $decimals decimal places.');
    }
    return BigInt.parse(whole + fraction.padRight(decimals, '0'));
  }

  static String format(BigInt value, int decimals, {int? maxFraction}) {
    final negative = value < BigInt.zero;
    final digits = value.abs().toString().padLeft(decimals + 1, '0');
    final whole = digits.substring(0, digits.length - decimals);
    var fraction = digits.substring(digits.length - decimals);
    if (maxFraction != null && fraction.length > maxFraction) {
      fraction = fraction.substring(0, maxFraction);
    }
    fraction = fraction.replaceFirst(RegExp(r'0+$'), '');
    final result = fraction.isEmpty ? whole : '$whole.$fraction';
    return negative ? '-$result' : result;
  }
}
