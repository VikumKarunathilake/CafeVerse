import 'package:flutter/material.dart';

class AppNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AppNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const List<AppNavItem> kDefaultNavItems = [
  AppNavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
  ),
  AppNavItem(
    icon: Icons.explore_outlined,
    activeIcon: Icons.explore_rounded,
    label: 'Explore',
  ),
  AppNavItem(
    icon: Icons.animation_outlined,
    activeIcon: Icons.animation_rounded,
    label: 'Anime',
  ),
  AppNavItem(
    icon: Icons.bookmark_border_rounded,
    activeIcon: Icons.bookmark_rounded,
    label: 'Watchlist',
  ),
];

/// Left-side Navigation Rail for desktop / landscape wide screens.
class AppNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onLogoTap;
  final VoidCallback? onSettingsTap;
  final List<AppNavItem> items;

  const AppNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.onLogoTap,
    this.onSettingsTap,
    this.items = kDefaultNavItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          // App Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 28),
            child: Tooltip(
              message: 'CafeVerse Cinema',
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onLogoTap ?? () => onDestinationSelected(0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_cafe_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),

          // Navigation destinations
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index;

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onDestinationSelected(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Avatar / Settings
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: IconButton.filledTonal(
              icon: const Icon(Icons.settings_outlined, size: 20),
              tooltip: 'Settings',
              onPressed: onSettingsTap ?? () {},
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom Navigation Bar for mobile / portrait screens.
class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppNavItem> items;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.items = kDefaultNavItems,
  });

  @override
  Widget build(BuildContext context) {
    // If selectedIndex is not within items range (e.g. -1), clamp safely
    final safeIndex = (selectedIndex >= 0 && selectedIndex < items.length)
        ? selectedIndex
        : 0;

    return NavigationBar(
      selectedIndex: safeIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: items.map((item) {
        return NavigationDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.activeIcon),
          label: item.label,
        );
      }).toList(),
    );
  }
}
