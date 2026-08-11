import 'package:flutter/material.dart';
import '../core/responsive.dart';
import '../widgets/app_navigation_bar.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void setSelectedIndex(int index) {
    if (mounted) {
      setState(() => _selectedIndex = index);
    }
  }

  String _getCategoryForIndex(int index) {
    switch (index) {
      case 1:
        return 'Trending';
      case 2:
        return 'Anime';
      case 3:
        return 'All';
      case 0:
      default:
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscapeWide =
            constraints.maxWidth > constraints.maxHeight &&
            constraints.maxWidth >= Breakpoints.medium;

        final currentBody = HomeScreen(
          key: ValueKey('home_tab_$_selectedIndex'),
          initialCategory: _getCategoryForIndex(_selectedIndex),
        );

        if (isLandscapeWide) {
          // Landscape / Desktop: Left Side Navigation Rail + Body
          return Scaffold(
            body: Row(
              children: [
                AppNavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: setSelectedIndex,
                  onLogoTap: () => setSelectedIndex(0),
                ),
                Expanded(child: currentBody),
              ],
            ),
          );
        } else {
          // Portrait & Mobile: Body + Bottom Navigation Bar
          return Scaffold(
            body: currentBody,
            bottomNavigationBar: AppBottomNavBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: setSelectedIndex,
            ),
          );
        }
      },
    );
  }
}
