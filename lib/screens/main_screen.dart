import 'package:flutter/material.dart';
import 'package:mindur/theme/app_background.dart';

import '../components/bottom_navbar.dart';
import 'chat_screen.dart';
import 'food_overview_screen.dart';
import 'habit_screen.dart';
import 'home_screen.dart';
import 'journal_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HabitScreen(),
    JournalScreen(),
    FoodOverviewScreen(),
    ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
      
        body: Stack(
          children: [
            // Main screen content
            Positioned.fill(child: _screens[_selectedIndex]),
      
            // ✅ KEEP your floating custom navbar
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: SafeArea(
                top: false,
                child: Center(
                  child: BottomNavbar(
                    currentIndex: _selectedIndex,
                    onTabChange: (newIndex) {
                      setState(() => _selectedIndex = newIndex);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
