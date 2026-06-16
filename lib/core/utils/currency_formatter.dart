import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String _symbol = 'FCFA';

  static void setCurrency(String symbol) {
    _symbol = symbol.isNotEmpty ? symbol : 'FCFA';
  }

  static String get symbol => _symbol;

  static String format(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount)} $_symbol';
  }

  static String formatInt(int amount) => format(amount.toDouble());
}
