import 'package:intl/intl.dart';

abstract final class Formatters {
  static String dateTime(DateTime value) =>
      DateFormat('dd.MM.yyyy HH:mm').format(value);

  static String fiat(double value, String currency) =>
      NumberFormat.simpleCurrency(name: currency).format(value);
}
