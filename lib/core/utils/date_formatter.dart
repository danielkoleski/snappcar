import 'package:intl/intl.dart';

final _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
final _dateTimeFormat = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');
final _monthYearFormat = DateFormat('MMMM yyyy', 'pt_BR');

String formatDate(DateTime? date) {
  if (date == null) return '—';
  return _dateFormat.format(date);
}

String formatDateTime(DateTime? date) {
  if (date == null) return '—';
  return _dateTimeFormat.format(date);
}

String formatMonthYear(DateTime? date) {
  if (date == null) return '—';
  return _monthYearFormat.format(date);
}

/// Returns a human-readable relative label (e.g. "vence em 3 dias", "vencido há 5 dias").
String formatDueDate(DateTime? dueDate) {
  if (dueDate == null) return '—';
  final diff = dueDate.difference(DateTime.now()).inDays;
  if (diff < 0) return 'Vencido há ${diff.abs()} dia${diff.abs() == 1 ? '' : 's'}';
  if (diff == 0) return 'Vence hoje';
  return 'Vence em $diff dia${diff == 1 ? '' : 's'}';
}
