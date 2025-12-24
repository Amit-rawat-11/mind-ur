import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final bool isPremium;
  final bool personalizedCompleted;

  final String? petSelection;
  final String? fitnessGoal;
  final String? appGoal;
  final String? journalReminder;
  final double? height;        // in cm
  final double? currentWeight; // in kg
  final double? goalWeight;    // in kg
  final double? age;           // calculated from DOB

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.isPremium,
    required this.personalizedCompleted,
    this.petSelection,
    this.fitnessGoal,
    this.appGoal,
    this.journalReminder,
    this.height,
    this.currentWeight,
    this.goalWeight,
    this.age,
  });

  /// ✅ Helper function to calculate age from DOB
  static int _calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  /// ✅ Factory constructor to build from Firestore Map
  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    double? age;

    // ✅ If DOB exists in Firestore, calculate age
    if (data['dob'] != null) {
      DateTime dob;

      if (data['dob'] is Timestamp) {
        dob = (data['dob'] as Timestamp).toDate();
      } else {
        dob = DateTime.tryParse(data['dob'].toString()) ?? DateTime.now();
      }

      age = _calculateAge(dob).toDouble(); // store as double for consistency
    }

    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      isPremium: data['isPremium'] ?? false,
      personalizedCompleted: data['personalizedCompleted'] ?? false,
      petSelection: data['petSelection'],
      fitnessGoal: data['fitnessGoal'],
      appGoal: data['appGoal'],
      journalReminder: data['journalReminder'],
      height: data['height'] != null ? (data['height'] as num).toDouble() : null,
      currentWeight: data['currentWeight'] != null ? (data['currentWeight'] as num).toDouble() : null,
      goalWeight: data['goalWeight'] != null ? (data['goalWeight'] as num).toDouble() : null,
      age: age, // ✅ dynamically computed
    );
  }

  /// ✅ Convert to Map for saving back to Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'isPremium': isPremium,
      'personalizedCompleted': personalizedCompleted,
      'petSelection': petSelection,
      'fitnessGoal': fitnessGoal,
      'appGoal': appGoal,
      'journalReminder': journalReminder,
      'height': height,
      'currentWeight': currentWeight,
      'goalWeight': goalWeight,
      // ❌ no need to save age (it’s calculated from dob)
    };
  }
}
