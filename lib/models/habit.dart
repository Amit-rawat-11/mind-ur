import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String? id;
  String title;
  String description;
  DateTime startDate;
  DateTime endDate;
  String priority;
  double progress;
  bool isCompleted;

  DateTime lastUpdated;
  DateTime? lastCompletedAt; // ✅ ADDED
  List<DateTime> completedDates;

  Habit({
    this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.priority,
    required this.progress,
    required this.isCompleted,
    required this.lastUpdated,
    required this.completedDates,
    this.lastCompletedAt, // ✅ ADDED
  });

  factory Habit.fromFirestore(Map<String, dynamic> data, String docId) {
    Timestamp? startTs = data['start_date'] as Timestamp?;
    Timestamp? endTs = data['end_date'] as Timestamp?;
    Timestamp? lastUpdatedTs = data['lastUpdated'] as Timestamp?;
    Timestamp? lastCompletedAtTs = data['lastCompletedAt'] as Timestamp?;

    return Habit(
      id: docId,
      title: data['title'] ?? '',
      description: data['desc'] ?? '',
      startDate: startTs != null ? startTs.toDate() : DateTime.now(),
      endDate: endTs != null ? endTs.toDate() : DateTime.now(),
      priority: data['priority'] ?? 'Low',
      progress: (data['progress'] ?? 0).toDouble(),
      isCompleted: data['isCompleted'] ?? false,
      lastUpdated:
          lastUpdatedTs != null ? lastUpdatedTs.toDate() : DateTime.now(),
      lastCompletedAt: lastCompletedAtTs != null
          ? lastCompletedAtTs.toDate()
          : null,
      completedDates: (data['completedDates'] as List<dynamic>?)
              ?.map((d) => (d as Timestamp).toDate())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'desc': description,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'priority': priority,
      'progress': progress,
      'isCompleted': isCompleted,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'lastCompletedAt':
          lastCompletedAt != null ? Timestamp.fromDate(lastCompletedAt!) : null,
      'completedDates':
          completedDates.map((d) => Timestamp.fromDate(d)).toList(),
    };
  }
}
