import 'dart:async';
import 'package:flutter/material.dart';
import '../models/movie_item.dart';
import 'app_cached_image.dart';

class HeroCarousel extends StatefulWidget {
  final List<MovieItem> items;
  final bool isLoading;
  final double height;
  final bool isWide;
  final ValueChanged<MovieItem> onMovieTap;

  const HeroCarousel({
    super.key,
    required this.items,
    this.isLoading = false,
    required this.height,
    required this.isWide,
    required this.onMovieTap,
  });

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  late PageController _controller;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 1.0);
    _startTimer();
  }

  @override
  void didUpdateWidget(HeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.items.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || widget.items.isEmpty) return;
      final next = (_currentIndex + 1) % widget.items.length;
      if (_controller.hasClients) {
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _prevHero() {
    if (widget.items.isEmpty || !_controller.hasClients) return;
    final prev = (_currentIndex - 1 + widget.items.length) % widget.items.length;
    _controller.animateToPage(
      prev,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _nextHero() {
    if (widget.items.isEmpty || !_controller.hasClients) return;
    final next = (_currentIndex + 1) % widget.items.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.items.isEmpty) {
      if (widget.isLoading) {
        return _buildSkeleton(theme);
      }
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: widget.items.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final hasImage =
                      item.backdropUrl != null || item.posterUrl != null;

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: item.gradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Backdrop / Poster image
                          if (hasImage)
                            AppCachedNetworkImage(
                              imageUrl: item.backdropUrl ?? item.posterUrl!,
                              fit: BoxFit.cover,
                              fallbackGradient: item.gradient,
                              fallbackIcon: item.icon,
                            ),

                          // Multi-gradient cinematic overlay
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.15),
                                  Colors.black.withValues(alpha: 0.35),
                                  Colors.black.withValues(alpha: 0.92),
                                ],
                                stops: const [0.0, 0.45, 1.0],
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.black.withValues(alpha: 0.8),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.65],
                              ),
                            ),
                          ),

                          // Background icon fallback
                          if (!hasImage)
                            Positioned(
                              right: -25,
                              bottom: -25,
                              child: Icon(
                                item.icon,
                                size: 240,
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),

                          // Hero Content
                          Padding(
                            padding: EdgeInsets.all(widget.isWide ? 28.0 : 18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Row: Badges
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.shadow
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            item.isAnime
                                                ? Icons.animation_rounded
                                                : Icons
                                                    .local_fire_department_rounded,
                                            size: 14,
                                            color: theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            item.tag,
                                            style: TextStyle(
                                              color: theme
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerLowest
                                            .withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: theme.colorScheme.outlineVariant
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            size: 16,
                                            color: theme.colorScheme.tertiary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.rating,
                                            style: TextStyle(
                                              color: theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '• ${item.year}',
                                            style: TextStyle(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const Spacer(),

                                // Title
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: widget.isWide ? 30 : 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    shadows: [
                                      Shadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.8),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // Subtitle / Overview
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        widget.isWide ? 640 : double.infinity,
                                  ),
                                  child: Text(
                                    item.overview,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.88),
                                      fontSize: widget.isWide ? 14 : 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Quick Action Buttons
                                Row(
                                  children: [
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.primary,
                                        foregroundColor:
                                            theme.colorScheme.onPrimary,
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                              widget.isWide ? 20 : 14,
                                          vertical: widget.isWide ? 12 : 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.play_arrow_rounded,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'Watch Now',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      onPressed: () => widget.onMovieTap(item),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Desktop Left & Right Chevrons
              if (widget.isWide) ...[
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerLowest
                            .withValues(alpha: 0.7),
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      onPressed: _prevHero,
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerLowest
                            .withValues(alpha: 0.7),
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                      icon: const Icon(Icons.chevron_right_rounded, size: 28),
                      onPressed: _nextHero,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildDots(theme),
      ],
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildDots(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.items.length, (index) {
        final isSelected = index == _currentIndex;
        return InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            _controller.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            height: 6,
            width: isSelected ? 24 : 6,
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(3),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
