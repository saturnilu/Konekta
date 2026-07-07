import 'package:intl/intl.dart';

class Format {
  static String currency(num value) {
    final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return f.format(value);
  }
  static String compact(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toString();
  }
  static String views(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M Views';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k Views';
    return '$value Views';
  }
  static String date(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    try {
      final dt = DateTime.parse(s);
      return DateFormat('MMM d, y').format(dt);
    } catch (_) {
      return s;
    }
  }
  static String timeAgo(dynamic v) {
    if (v == null) return '';
    try {
      final dt = DateTime.parse(v.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d').format(dt);
    } catch (_) { return ''; }
  }
  static String chatTime(dynamic v) {
    if (v == null) return '';
    try {
      final dt = DateTime.parse(v.toString());
      return DateFormat('h:mm a').format(dt);
    } catch (_) { return ''; }
  }
}
