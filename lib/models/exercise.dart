class Workout {
  final String name;
  final String category;
  final String muscleGroup;
  final String equipment;
  final String instructions;
  final bool isBodyweight;
  final List<String> searchKeywords;

  Workout({
    required this.name,
    required this.category,
    required this.muscleGroup,
    required this.equipment,
    required this.instructions,
    required this.isBodyweight,
    required this.searchKeywords,
  });

  // Factory constructor for creating a Workout from a Map
  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      muscleGroup: map['muscleGroup'] ?? '',
      equipment: map['equipment'] ?? '',
      instructions: map['instructions'] ?? '',
      isBodyweight: map['isBodyweight'] ?? false,
      searchKeywords: List<String>.from(map['searchKeywords'] ?? []),
    );
  }

  // Convert a Workout object to a Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'muscleGroup': muscleGroup,
      'equipment': equipment,
      'instructions': instructions,
      'isBodyweight': isBodyweight,
      'searchKeywords': searchKeywords,
    };
  }
}


