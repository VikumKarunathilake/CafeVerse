import 'package:flutter/material.dart';
import '../core/responsive.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<({IconData icon, IconData activeIcon, String label})> _navItems = const [
    (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'Explore'),
    (icon: Icons.animation_outlined, activeIcon: Icons.animation_rounded, label: 'Anime'),
    (icon: Icons.bookmark_border_rounded, activeIcon: Icons.bookmark_rounded, label: 'Watchlist'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscapeWide = constraints.maxWidth > constraints.maxHeight &&
            constraints.maxWidth >= Breakpoints.medium;

        if (isLandscapeWide) {
          // Landscape / Desktop: Left Side Navigation Rail
          return Scaffold(
            body: Row(
              children: [
                Container(
                  width: 88,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      right: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // App Logo
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 24, 0, 28),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.tertiary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.local_cafe_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),

                      // Navigation destinations
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: _navItems.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _navItems[index];
                            final isSelected = _selectedIndex == index;

                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => setState(() => _selectedIndex = index),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
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
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                const Expanded(
                  child: HomeScreen(),
                ),
              ],
            ),
          );
        } else {
          // Portrait & Mobile: Bottom Navigation Bar
          return Scaffold(
            body: const HomeScreen(),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              destinations: _navItems.map((item) {
                return NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: item.label,
                );
              }).toList(),
            ),
          );
        }
      },
    );
  }
}
