import 'package:intl/intl.dart';


class TimeUtils {
  static String get formattedDate {
    final now = DateTime.now();
    return DateFormat('d MMMM y').format(now); // e.g., 2 May 2025
  }

  static String get formattedTime {
    final now = DateTime.now();
    return DateFormat('h:mm a').format(now); // e.g., 5:20 PM
  }

    static String get dayName {
    final now = DateTime.now();
    return DateFormat('EEEE').format(now); // e.g., Friday
  }
}


class GreetingUtil {
  /// Returns a greeting based on current local time
  ///
  /// Morning   → 05:00 – 11:59
  /// Afternoon → 12:00 – 16:59
  /// Evening   → 17:00 – 20:59
  /// Night     → 21:00 – 04:59
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon";
    } else if (hour >= 17 && hour < 21) {
      return "Good Evening";
    } else {
      return "Good Night";
    }
  }
}
