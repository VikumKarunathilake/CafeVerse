import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final double horizontalPadding;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onNotificationsPressed;

  const HomeHeader({
    super.key,
    required this.horizontalPadding,
    this.onSearchPressed,
    this.onNotificationsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child: const Icon(
              Icons.local_cafe_rounded,
              color: Colors.brown,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CafeVerse',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton.filledTonal(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
            onPressed: onSearchPressed ?? () {},
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: onNotificationsPressed ?? () {},
          ),
        ],
      ),
    );
  }
}
