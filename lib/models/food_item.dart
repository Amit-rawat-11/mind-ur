import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String name;
  final int quantity;
  final int calories;
  final int protein;

  FoodItem({
    required this.name,
    required this.quantity,
    required this.calories,
    required this.protein,
  });

  // Factory method to create a FoodItem from Firestore data
  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      calories: data['calories'] ?? 0,
      protein: data['protein'] ?? 0,
    );
  }
}
