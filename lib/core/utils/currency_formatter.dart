import 'package:intl/intl.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
  decimalDigits: 2,
);

String formatBrl(num? value) {
  if (value == null) return r'R$ —';
  return _currencyFormat.format(value);
}

/// Parses a BRL-formatted string back to double. Returns null on failure.
double? parseBrl(String value) {
  try {
    return _currencyFormat.parse(value).toDouble();
  } catch (_) {
    return null;
  }
}
