import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindur/components/carousel_widget/cw_calories.dart';
import 'package:mindur/theme/app_background.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../components/carousel_widget/cw_protein.dart';
import '../components/recent_entry_card.dart';
import '../models/user_profile.dart';
import '../services/firebase_service.dart';
import '../utils/nutrition_calculator.dart';
import 'food_search_screen.dart';


class FoodOverviewScreen extends StatefulWidget {
  const FoodOverviewScreen({super.key});

  @override
  State<FoodOverviewScreen> createState() => _FoodOverviewScreenState();
}

class _FoodOverviewScreenState extends State<FoodOverviewScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final PageController pageController = PageController();

  bool isLoading = true;
  num totalCalories = 0;
  num totalProtein = 0;

  int usercalgoal = 2500;
  int userproteingoal = 90;

  UserProfile? userProfile;
  final firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    fetchUserData();
    loadSummary();
  }

  Future<void> fetchUserData() async {
    final profile = await firestoreService.fetchUserProfile();
    if (!mounted) return;

    setState(() {
      userProfile = profile;
    });

    if (profile != null &&
        profile.currentWeight != null &&
        profile.fitnessGoal != null) {
      final goals = NutritionCalculator.calculate(
        weight: profile.currentWeight ?? 60.0,
        goal: profile.fitnessGoal ?? "Get in Shape",
        height: profile.height ?? 150.0,
        age: profile.age ?? 18,
      );

      setState(() {
        usercalgoal = goals["calories"]!.toInt();
        userproteingoal = goals["protein"]!.toInt();
      });
    }
  }

  Future<void> loadSummary() async {
    final summary = await firestoreService.fetchTodayFoodSummary();
    if (!mounted) return;

    setState(() {
      totalCalories = summary['calories'];
      totalProtein = summary['protein'];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Food Tracking"),
          backgroundColor: Colors.transparent,
          foregroundColor: colors.onSurface,
          elevation: 0,
        ),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🔹 Calories / Protein Carousel
                      SizedBox(
                        height: 250,
                        width: double.infinity,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 150,
                              child: PageView(
                                controller: pageController,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: CwCalories(
                                      usercalgoal: usercalgoal,
                                      totalCalories: totalCalories,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: CwProtein(
                                      totalProtein: totalProtein,
                                      userProteingoal: userproteingoal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SmoothPageIndicator(
                              controller: pageController,
                              count: 2,
                              effect: JumpingDotEffect(
                                verticalOffset: 10,
                                dotColor: colors.outlineVariant.withOpacity(0.6),
                                activeDotColor: colors.primary,
                                jumpScale: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 48,
                              width: 250,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const FoodSearchSceen(),
                                    ),
                                  ).then((_) => loadSummary());
                                },
                                child: const Text('Log Food'),
                              ),
                            ),
                          ],
                        ),
                      ),
      
                      const SizedBox(height: 12),
      
                      Text(
                        "Today's Food Logs",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
      
                      const SizedBox(height: 8),
      
                      /// 🔹 Food Logs List
                      Expanded(
                        child: FutureBuilder<QuerySnapshot>(
                          future: firestoreService.fetchTodayFoodLogs(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
      
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  "Error: ${snapshot.error}",
                                  style: theme.textTheme.bodyMedium,
                                ),
                              );
                            }
      
                            final docs = snapshot.data!.docs;
      
                            if (docs.isEmpty) {
                              return Text(
                                "No food logged today.",
                                style: theme.textTheme.bodyMedium,
                              );
                            }
      
                            return ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                return RecentEntryCard(
                                  text: doc['name'],
                                  subtitle:
                                      "${doc['calories']} Kcals • ${doc['protein']}g Protein • Qty: ${doc['quantity']}",
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
