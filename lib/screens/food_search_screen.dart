import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:mindur/theme/app_background.dart';

import '../components/search_card.dart';
import '../models/food_item.dart';
import '../services/firebase_service.dart';
import 'AddFoodEntryScreen.dart';

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
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> fetchAllFoods() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('foods').get();

      final data = snapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        allFoods = data;
        searchResults = data;
        isLoading = false;
      });

      _fadeController.forward();
    } catch (e) {
      debugPrint("Error fetching foods: $e");
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
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FoodLoggingScreen(),
                  ),
                );
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
                                onChanged: updateSearch,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      colors.surfaceVariant.withOpacity(0.6),
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
                                      setState(
                                          () => highProteinOnly = value);
                                      updateSearch('');
                                    },
                                  ),
                                  const Spacer(),
                                  Text(
                                    '🥦 Veg',
                                    style: theme.textTheme.bodyMedium,
                                  ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemBuilder: (context, index) {
                                final food = searchResults[index];
      
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 12),
                                  child: SearchCard(
                                    witdh: width,
                                    height: height * 0.08,
                                    title:
                                        "${food['isVeg'] == true ? '🌱' : '🍗'} ${food['name']}",
                                    description:
                                        "${food['protein']}g Protein | ${food['calories']} Cal | ${food['servingSize']}",
                                    onPressed: () async {
                                      final result = await showDialog<int>(
                                        context: context,
                                        builder: (context) {
                                          final controller =
                                              TextEditingController(
                                                  text: "1");
      
                                          return AlertDialog(
                                            backgroundColor:
                                                colors.surface,
                                            title:
                                                const Text('Enter Quantity'),
                                            content: SizedBox(
                                              width: width,
                                              child: Column(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
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
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                  const SizedBox(height: 16),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context),
                                                child:
                                                    const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(
                                                    int.tryParse(
                                                          controller.text,
                                                        ) ??
                                                        1,
                                                  );
                                                },
                                                child:
                                                    const Text("Log Food"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
      
                                      if (result != null) {
                                        final foodItem = FoodItem(
                                          name: food['name'],
                                          quantity: result,
                                          calories:
                                              food['calories'] * result,
                                          protein:
                                              food['protein'] * result,
                                        );
      
                                        firestoreService.logFood(foodItem);
      
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${foodItem.name} x$result logged!',
                                            ),
                                          ),
                                        );
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
