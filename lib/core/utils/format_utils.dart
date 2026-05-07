class FormatUtils {
  FormatUtils._();

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    }
    if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  static String timeAgo(DateTime dateTime, {String localeCode = 'en'}) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final isSpanish = localeCode == 'es';

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return isSpanish ? 'hace ${years}a' : '${years}y ago';
    }
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return isSpanish ? 'hace ${months}m' : '${months}mo ago';
    }
    if (difference.inDays > 0) {
      return isSpanish
          ? 'hace ${difference.inDays}d'
          : '${difference.inDays}d ago';
    }
    if (difference.inHours > 0) {
      return isSpanish
          ? 'hace ${difference.inHours}h'
          : '${difference.inHours}h ago';
    }
    if (difference.inMinutes > 0) {
      return isSpanish
          ? 'hace ${difference.inMinutes}min'
          : '${difference.inMinutes}m ago';
    }
    return isSpanish ? 'Ahora' : 'Just now';
  }
}
