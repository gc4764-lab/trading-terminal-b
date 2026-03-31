import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  
  static final NumberFormat _percentFormat = NumberFormat.percentPattern(
    locale: 'en_US',
  );
  
  static final NumberFormat _numberFormat = NumberFormat('#,###');
  
  static String formatCurrency(double value) {
    return _currencyFormat.format(value);
  }
  
  static String formatPercent(double value) {
    return _percentFormat.format(value / 100);
  }
  
  static String formatNumber(int value) {
    return _numberFormat.format(value);
  }
  
  static String formatCompactNumber(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
  
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }
  
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    }
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    }
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    }
    return 'just now';
  }
  
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    }
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    }
    return '${duration.inSeconds}s';
  }
}