import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutLog {
  final String exercise;
  final String muscleGroup;
  final List<WorkoutSet> sets;
  final Duration duration;
  final double totalVolume;
  final double caloriesBurned;
  final DateTime timestamp;

  WorkoutLog({
    required this.exercise,
    required this.muscleGroup,
    required this.sets,
    required this.duration,
    required this.totalVolume,
    required this.caloriesBurned,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'exercise': exercise,
      'muscleGroup': muscleGroup,
      'sets': sets.map((s) => s.toMap()).toList(),
      'duration': duration.inSeconds, // store as seconds
      'totalVolume': totalVolume,
      'caloriesBurned': caloriesBurned,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory WorkoutLog.fromMap(Map<String, dynamic> map) {
    return WorkoutLog(
      exercise: map['exercise'] ?? '',
      muscleGroup: map['muscleGroup'] ?? '',
      sets: (map['sets'] as List<dynamic>? ?? [])
          .map((s) => WorkoutSet.fromMap(s as Map<String, dynamic>))
          .toList(),
      duration: Duration(seconds: map['duration'] ?? 0),
      totalVolume: (map['totalVolume'] ?? 0).toDouble(),
      caloriesBurned: (map['caloriesBurned'] ?? 0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class WorkoutSet {
  final double previousWeight;
  final double kg;
  final int reps;

  WorkoutSet({
    required this.previousWeight,
    required this.kg,
    required this.reps,
  });

  Map<String, dynamic> toMap() {
    return {
      'previousWeight': previousWeight,
      'kg': kg,
      'reps': reps,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      previousWeight: (map['previousWeight'] ?? 0).toDouble(),
      kg: (map['kg'] ?? 0).toDouble(),
      reps: map['reps'] ?? 0,
    );
  }
}
