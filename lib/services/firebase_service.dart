import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/food_item.dart';
import '../models/habit.dart';
import '../models/journal.dart';
import '../models/user_profile.dart';
import '../utils/journal_streak_util.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 Helper to get current user UID
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// ✅ Fetch full user profile with model
  Future<UserProfile?> fetchUserProfile() async {
    if (_uid == null) return null;

    try {
      final doc = await _db.collection('users').doc(_uid).get();
      if (!doc.exists) return null;

      return UserProfile.fromMap(_uid!, doc.data()!);
    } catch (e) {
      print("Error fetching user profile: $e");
      return null;
    }
  }

  Future<void> updateDisplayName(String name) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'displayName': name,
    });
  }

  // ---------------- JOURNAL ----------------
  Future<void> addJournalEntry(JournalEntry entry) async {
    final uid = _uid;
    if (uid == null) return;

    final userDoc = _db.collection('users').doc(uid);

    try {
      await userDoc.collection('journals').add({
        'title': entry.title,
        'content': entry.content,
        'timestamp': entry.timestamp,
      });

      final updatedStreakData = await JournalStreakUtil.getJournalStreak(uid);

      await userDoc.set({
        'journalStreak': {
          'currentStreak': updatedStreakData['currentStreak'],
          'longestStreak': updatedStreakData['longestStreak'],
          'lastEntryDate': Timestamp.fromDate(DateTime.now()),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving journal entry or updating streak: $e");
    }
  }

  Future<void> updateJournalEntry(String documentId, JournalEntry entry) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('journals')
          .doc(documentId)
          .update({
            'title': entry.title,
            'content': entry.content,
            'timestamp': entry.timestamp,
          });
    } catch (e) {
      debugPrint("Error updating journal entry: $e");
    }
  }

  Future<JournalEntry?> getJournalEntry(String documentId) async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('journals')
          .doc(documentId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return JournalEntry(
        title: data['title'],
        content: data['content'],
        timestamp: (data['timestamp'] as Timestamp).toDate(),
      );
    } catch (e) {
      debugPrint("Error fetching journal entry: $e");
      return null;
    }
  }

  // ---------------- HABIT (UPDATED) ----------------
  Future<void> addHabits(Habit habit) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db.collection('users').doc(uid).collection('habits').add({
        'title': habit.title,
        'desc': habit.description,
        'start_date': habit.startDate,
        'end_date': habit.endDate,
        'priority': habit.priority,
        'progress': habit.progress,
        'isCompleted': habit.isCompleted,
        'lastUpdated': habit.lastUpdated,
        'completedDates': habit.completedDates,
        // ADDED THIS:
        'lastCompletedAt': habit.isCompleted
            ? FieldValue.serverTimestamp()
            : null,
      });
    } catch (e) {
      debugPrint("Error saving habits: $e");
    }
  }

  Future<List<Habit>> fetchHabits() async {
    final uid = _uid; // FIX: Define uid so the query can run
    if (uid == null) return [];

    DateTime parseTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    List<DateTime> parseCompletedDates(dynamic value) {
      if (value is List) {
        return value.map((d) {
          if (d is Timestamp) return d.toDate();
          if (d is DateTime) return d;
          return DateTime.now();
        }).toList();
      }
      return [];
    }

    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('habits')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Habit(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['desc'] ?? '',
          progress: (data['progress'] ?? 0.0).toDouble(),
          priority: data['priority'] ?? 'Medium',
          isCompleted: data['isCompleted'] ?? false,
          startDate: parseTimestamp(data['start_date']),
          endDate: parseTimestamp(data['end_date']),
          lastUpdated: parseTimestamp(data['lastUpdated']),
          completedDates: parseCompletedDates(data['completedDates']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching habits: $e');
      return [];
    }
  }

  Future<void> updateHabit(String documentId, Habit habit) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('habits')
          .doc(documentId)
          .update({
            'title': habit.title,
            'desc': habit.description,
            'start_date': habit.startDate,
            'end_date': habit.endDate,
            'priority': habit.priority,
            'progress': habit.progress,
            'isCompleted': habit.isCompleted,
            'lastUpdated': habit.lastUpdated,
            'completedDates': habit.completedDates,
            // ADDED THIS: Crucial for the "Daily Reset" logic
            'lastCompletedAt': habit.isCompleted
                ? FieldValue.serverTimestamp()
                : null,
                
          });
          
    } catch (e) {
      debugPrint("Error updating habit: $e");
    }
  }

  Future<void> deleteHabit(String habitId) async {
    final uid = _uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('habits')
        .doc(habitId)
        .delete();
  }

  // ---------------- FOOD ----------------
  Future<void> logFood(FoodItem food) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db.collection('users').doc(uid).collection('foodlogging').add({
        'name': food.name,
        'quantity': food.quantity,
        'calories': food.calories,
        'protein': food.protein,
        'updatedcalories': food.calories,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      debugPrint("Error logging food: $e");
    }
  }

  Future<Map<String, dynamic>> fetchTodayFoodSummary() async {
    final uid = _uid;
    if (uid == null) return {'calories': 0, 'protein': 0};

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    try {
      final foodSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('foodlogging')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .get();

      num totalCalories = 0;
      num totalProtein = 0;

      for (final doc in foodSnapshot.docs) {
        final data = doc.data();
        totalCalories += data['calories'] ?? 0;
        totalProtein += data['protein'] ?? 0;
      }
      return {'calories': totalCalories, 'protein': totalProtein};
    } catch (e) {
      debugPrint("Error fetching food summary: $e");
      return {'calories': 0, 'protein': 0};
    }
  }

  Future<void> cleanOldFoodLogs() async {
    final uid = _uid;
    if (uid == null) return;

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);

    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('foodlogging')
          .get();

      for (final doc in snapshot.docs) {
        final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
        if (timestamp.isBefore(start)) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      debugPrint("Error cleaning old food logs: $e");
    }
  }

  Future<QuerySnapshot> fetchTodayFoodLogs() async {
    if (_uid == null) throw Exception("User not logged in");

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return _db
        .collection('users')
        .doc(_uid)
        .collection('foodlogging')
        .where('timestamp', isGreaterThanOrEqualTo: todayStart)
        .orderBy('timestamp', descending: true)
        .get();
  }

  // ---------------- AI SESSION ----------------
  Future<void> deleteSession(String sessionId) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final sessionRef = _db
          .collection('users')
          .doc(uid)
          .collection('ai_sessions')
          .doc(sessionId);

      final messages = await sessionRef.collection('messages').get();
      final batch = _db.batch();

      for (final msg in messages.docs) {
        batch.delete(msg.reference);
      }

      await batch.commit();
      await sessionRef.delete();
    } catch (e) {
      debugPrint("Delete session error: $e");
    }
  }

  // ---------------- PERSONALIZATION ----------------
  Future<void> saveUserPersonalization({
    required String petSelection,
    required String fitnessGoal,
    required String appGoal,
    required String journalReminder,
    required double height,
    required double currentWeight,
    required double goalWeight,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db.collection('users').doc(uid).set({
        'petSelection': petSelection,
        'fitnessGoal': fitnessGoal,
        'appGoal': appGoal,
        'journalReminder': journalReminder,
        'height': height,
        'currentWeight': currentWeight,
        'goalWeight': goalWeight,
        'personalizedCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // do NOT overwrite signup data
    } catch (e) {
      debugPrint("Error saving personalization: $e");
    }
  }

  // ---------------- AI MEMORY ----------------

  Future<List<String>> getAiMemory() async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('ai_profile')
          .doc('memory')
          .get();

      if (!doc.exists) return [];

      final data = doc.data();
      final insights = data?['insights'];

      if (insights is List) {
        return insights.cast<String>();
      }

      return [];
    } catch (e) {
      debugPrint("Error fetching AI memory: $e");
      return [];
    }
  }

  Future<void> updateAiMemory(List<String> insights) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('ai_profile')
          .doc('memory')
          .set({
            'insights': insights,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating AI memory: $e");
    }
  }
}
