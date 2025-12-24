import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 65,
          decoration: BoxDecoration(
            // ✅ Glass surface using theme colors
            color: theme.colorScheme.surface.withOpacity(isDark ? 0.75 : 0.9),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBtn(
                icon: LucideIcons.layoutDashboard,
                index: 0,
                currentIndex: currentIndex,
                onTap: onTabChange,
              ),
              _NavBtn(
                icon: LucideIcons.calendarCheck,
                index: 1,
                currentIndex: currentIndex,
                onTap: onTabChange,
              ),
              _NavBtn(
                icon: LucideIcons.bookOpen,
                index: 2,
                currentIndex: currentIndex,
                onTap: onTabChange,
              ),
              _NavBtn(
                icon: LucideIcons.utensilsCrossed,
                index: 3,
                currentIndex: currentIndex,
                onTap: onTabChange,
              ),
              _NavBtn(
                icon: LucideIcons.brainCog,
                index: 4,
                currentIndex: currentIndex,
                onTap: onTabChange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _NavBtn({
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isActive = currentIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Icon(
          icon,
          size: isActive ? 26 : 22,
          color: isActive
              // ✅ Sage Mint accent
              ? theme.colorScheme.primary
              // ✅ Muted inactive icon
              : theme.textTheme.bodyMedium!.color!.withOpacity(0.6),
        ),
      ),
    );
  }
}
