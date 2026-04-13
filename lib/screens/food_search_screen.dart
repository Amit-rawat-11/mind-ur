import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:mindur/theme/app_background.dart';

import '../components/search_card.dart';
import '../models/food_item.dart';
import '../services/analytics_service.dart';
import '../services/firebase_service.dart';

class FoodSearchSceen extends StatefulWidget {
  const FoodSearchSceen({super.key});

  @override
  State<FoodSearchSceen> createState() => _FoodSearchSceenState();
}

class _FoodSearchSceenState extends State<FoodSearchSceen>
    with SingleTickerProviderStateMixin {
  final firestoreService = FirestoreService();

  List<Map<String, dynamic>> allFoods = [];
  List<Map<String, dynamic>> searchResults = [];

  bool isLoading = true;
  bool vegOnly = false;
  bool highProteinOnly = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    fetchAllFoods();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> fetchAllFoods() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('foods')
          .get();

      final data = snapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        allFoods = data;
        searchResults = data;
        isLoading = false;
      });

      _fadeController.forward();
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void updateSearch(String value) {
    final query = value.toLowerCase();
    List<Map<String, dynamic>> results = allFoods;

    if (vegOnly) {
      results = results.where((f) => f['isVeg'] == true).toList();
    }

    if (highProteinOnly) {
      results = results.where((f) => f['isHighProtein'] == true).toList();
    }

    results = results.where((food) {
      final keywords = List<String>.from(food['searchKeywords'] ?? []);
      return keywords.any((k) => k.toLowerCase().contains(query));
    }).toList();

    setState(() {
      searchResults = results;
    });

    _fadeController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Search Food Items'),
          backgroundColor: Colors.transparent,
          foregroundColor: colors.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              onPressed: () {
                context.pushNamed('food-add');
              },
              icon: const Icon(LucideIcons.edit),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : allFoods.isEmpty
              ? Center(
                  child: Text(
                    "No food items found",
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            onChanged: (value) {
                              updateSearch(value);

                              // ✅ LOG FOOD SEARCH (only if query is meaningful)
                              if (value.trim().length > 2) {
                                AnalyticsService().logFoodSearch(
                                  query: value.trim(),
                                );
                              }
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: colors.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                              hintText: 'Search for food',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                '💪 High Protein',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Switch(
                                value: highProteinOnly,
                                onChanged: (value) {
                                  setState(() => highProteinOnly = value);
                                  updateSearch('');
                                },
                              ),
                              const Spacer(),
                              Text('🥦 Veg', style: theme.textTheme.bodyMedium),
                              Switch(
                                value: vegOnly,
                                onChanged: (value) {
                                  setState(() => vegOnly = value);
                                  updateSearch('');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ListView.builder(
                          itemCount: searchResults.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final food = searchResults[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SearchCard(
                                witdh: width,
                                height: height * 0.08,
                                title:
                                    "${food['isVeg'] == true ? '🌱' : '🍗'} ${food['name']}",
                                description:
                                    "${food['protein']}g Protein | ${food['calories']} Cal | ${food['servingSize']}",
                                onPressed: () async {
                                  // Capture messenger before any async gap
                                  final messenger = ScaffoldMessenger.of(context);

                                  final result = await showDialog<int>(
                                    context: context,
                                    builder: (context) {
                                      final controller = TextEditingController(
                                        text: "1",
                                      );

                                      return AlertDialog(
                                        backgroundColor: colors.surface,
                                        title: const Text('Enter Quantity'),
                                        content: SizedBox(
                                          width: width,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              TextField(
                                                controller: controller,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                      hintText:
                                                          "How many servings?",
                                                    ),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                "Serving Size: ${food['servingSize']}",
                                                style:
                                                    theme.textTheme.bodySmall,
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => context.pop(),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              context.pop(
                                                int.tryParse(
                                                  controller.text.trim(),
                                                ),
                                              );
                                            },
                                            child: const Text("Log Food"),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (result != null) {
                                    // ✅ FIX BUG #4: Cast Firestore num (may be double) to int
                                    // safely with .round() to avoid silent runtime type errors
                                    // that caused specific food items to always fail logging.
                                    final calories = (food['calories'] as num).round();
                                    final protein = (food['protein'] as num).round();

                                    final foodItem = FoodItem(
                                      name: food['name'],
                                      quantity: result,
                                      calories: calories * result,
                                      protein: protein * result,
                                    );

                                    // ✅ FIX BUG #3: Added `await` — without this the
                                    // Firestore write was fire-and-forget and dropped silently
                                    // when the user navigated away quickly.
                                    await firestoreService.logFood(foodItem);

                                    // ✅ LOG FOOD LOGGED
                                    await AnalyticsService().logFoodLogged(
                                      foodName: foodItem.name,
                                      calories: foodItem.calories,
                                      protein: foodItem.protein,
                                    );

                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${foodItem.name} x$result logged!',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
