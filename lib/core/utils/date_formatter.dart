import 'package:intl/intl.dart';

class DateFormatter {
  static String format(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  static String formatLong(DateTime date) {
    return DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date);
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return 'Il y a ${diff.inDays} jour(s)';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours} heure(s)';
    return 'Il y a ${diff.inMinutes} minute(s)';
  }
}
