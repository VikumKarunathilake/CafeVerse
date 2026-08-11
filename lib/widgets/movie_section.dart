import 'package:flutter/material.dart';
import '../models/movie_item.dart';
import 'movie_card.dart';

class MovieSection extends StatelessWidget {
  final String title;
  final String emoji;
  final List<MovieItem> items;
  final bool isLoading;
  final double horizontalPadding;
  final double cardWidth;
  final double cardHeight;
  final double sectionHeight;
  final MovieCardType cardType;
  final ValueChanged<MovieItem> onMovieTap;
  final VoidCallback? onSeeAll;

  const MovieSection({
    super.key,
    required this.title,
    required this.emoji,
    required this.items,
    this.isLoading = false,
    required this.horizontalPadding,
    required this.cardWidth,
    required this.cardHeight,
    required this.sectionHeight,
    this.cardType = MovieCardType.poster,
    required this.onMovieTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              Text(
                '$emoji $title',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSeeAll ?? () {},
                child: const Text(
                  'See all',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: sectionHeight,
          child: isLoading
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  itemCount: 6,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, index) => MovieCardSkeleton(
                    width: cardWidth,
                    height: cardHeight,
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return MovieCard(
                      item: item,
                      width: cardWidth,
                      height: cardHeight,
                      cardType: cardType,
                      onTap: () => onMovieTap(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
