class DateTimeUtils {
  // Format DateTime to a readable string
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  // Check if a DateTime is in the past
  static bool isPast(DateTime dateTime) {
    return dateTime.isBefore(DateTime.now());
  }
}
