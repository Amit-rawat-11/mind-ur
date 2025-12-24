// journal_streak_util.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class JournalStreakUtil {
  static Future<Map<String, int>> getJournalStreak(String uid) async {
    final journalRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('journals');

    final snapshot = await journalRef.orderBy('timestamp', descending: true).get();

    final List<DateTime> journalDates = snapshot.docs
        .map((doc) => (doc['timestamp'] as Timestamp).toDate())
        .map((d) => DateTime(d.year, d.month, d.day))
        .toList();

    journalDates.sort((a, b) => b.compareTo(a)); // descending

    int currentStreak = 0;
    int longestStreak = 0;

    DateTime today = DateTime.now();
    DateTime expectedDate = DateTime(today.year, today.month, today.day);

    for (final date in journalDates) {
      if (date == expectedDate) {
        currentStreak++;
        expectedDate = expectedDate.subtract(Duration(days: 1));
      } else if (date.isBefore(expectedDate)) {
        if (date == expectedDate.subtract(Duration(days: 1))) {
          currentStreak++;
          expectedDate = expectedDate.subtract(Duration(days: 1));
        } else {
          break;
        }
      }
    }

    // For longest streak calculation
    int streak = 1;
    for (int i = 1; i < journalDates.length; i++) {
      if (journalDates[i].difference(journalDates[i - 1]).inDays == 1) {
        streak++;
      } else {
        longestStreak = streak > longestStreak ? streak : longestStreak;
        streak = 1;
      }
    }
    longestStreak = streak > longestStreak ? streak : longestStreak;

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }
}
