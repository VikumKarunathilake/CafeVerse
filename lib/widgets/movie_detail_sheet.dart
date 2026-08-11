import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/movie_item.dart';
import 'app_cached_image.dart';
import 'image_lightbox_dialog.dart';
import '../screens/main_shell.dart';
import '../screens/movie_player_screen.dart';

class MovieDetailSheet extends StatefulWidget {
  final MovieItem item;

  const MovieDetailSheet({
    super.key,
    required this.item,
  });

  static Future<void> show(BuildContext context, MovieItem item) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final double sheetMaxWidth;
    if (screenWidth >= 1600) {
      sheetMaxWidth = 1180;
    } else if (screenWidth >= 1200) {
      sheetMaxWidth = 1060;
    } else if (screenWidth >= 900) {
      sheetMaxWidth = 880;
    } else if (screenWidth >= 650) {
      sheetMaxWidth = 640;
    } else {
      sheetMaxWidth = double.infinity;
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: sheetMaxWidth,
      ),
      builder: (context) => MovieDetailSheet(item: item),
    );
  }

  @override
  State<MovieDetailSheet> createState() => _MovieDetailSheetState();
}

class _MovieDetailSheetState extends State<MovieDetailSheet> {
  bool _isInWatchlist = false;

  void _toggleWatchlist() {
    setState(() => _isInWatchlist = !_isInWatchlist);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isInWatchlist
                  ? Icons.bookmark_added_rounded
                  : Icons.bookmark_remove_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isInWatchlist
                    ? 'Added "${widget.item.title}" to your Watchlist'
                    : 'Removed "${widget.item.title}" from Watchlist',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openPlayer() async {
    final mainShell = context.findAncestorStateOfType<MainShellState>();
    final selectedMovie = widget.item;
    final navContext = Navigator.of(context).context;
    Navigator.of(context).pop();
    final tabIndex = await MoviePlayerScreen.open(navContext, selectedMovie);
    if (tabIndex != null) {
      mainShell?.setSelectedIndex(tabIndex);
    }
  }

  void _shareMovie() {
    final text = '${widget.item.title} (${widget.item.year})\n'
        'Rating: ${widget.item.rating}/10\n'
        '${widget.item.overview}\n'
        '${widget.item.homepage ?? ''}';
    Clipboard.setData(ClipboardData(text: text.trim()));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.copy_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Movie information copied to clipboard!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _copyText(String label, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('$label copied to clipboard!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final hasBackdrop = item.backdropUrl != null || item.posterUrl != null;
    final hasPoster = item.posterUrl != null || item.backdropUrl != null;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.90,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 740;

              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomInset + 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Backdrop Header
                    _buildBackdropHeader(theme, item, hasBackdrop, isWide),

                    // 2. Main Content Body (Responsive Wide 2-Column vs Compact 1-Column)
                    if (isWide)
                      _buildWideLayout(theme, item, hasPoster)
                    else
                      _buildCompactLayout(theme, item, hasPoster),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- Backdrop Header ---
  Widget _buildBackdropHeader(
    ThemeData theme,
    MovieItem item,
    bool hasBackdrop,
    bool isWide,
  ) {
    final backdropHeight = isWide ? 260.0 : 210.0;
    final backdropImageUrl = item.backdropUrl ?? item.posterUrl;

    return Stack(
      children: [
        if (hasBackdrop && backdropImageUrl != null)
          InkWell(
            onTap: () => ImageLightboxDialog.show(
              context,
              imageUrl: backdropImageUrl,
              title: item.title,
              subtitle: item.tagline ?? item.originalTitle,
              resolutionLabel: 'HD Backdrop (1280×720)',
              fallbackGradient: item.gradient,
              fallbackIcon: item.icon,
            ),
            child: SizedBox(
              height: backdropHeight,
              width: double.infinity,
              child: AppCachedNetworkImage(
                imageUrl: backdropImageUrl,
                fit: BoxFit.cover,
                fallbackGradient: item.gradient,
                fallbackIcon: item.icon,
              ),
            ),
          )
        else
          Container(
            height: backdropHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: item.gradient,
              ),
            ),
            child: Center(
              child: Icon(
                item.icon,
                size: 90,
                color: Colors.white24,
              ),
            ),
          ),

        // Gradient fade over backdrop
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    theme.colorScheme.surface.withValues(alpha: 0.85),
                    theme.colorScheme.surface,
                  ],
                  stops: const [0.0, 0.35, 0.78, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Top Drag Indicator Pill
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),

        // Close Button
        Positioned(
          top: 12,
          right: 14,
          child: IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor:
                  theme.colorScheme.surface.withValues(alpha: 0.85),
              foregroundColor: theme.colorScheme.onSurface,
            ),
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  // --- Wide 2-Column Desktop / Tablet Layout ---
  Widget _buildWideLayout(ThemeData theme, MovieItem item, bool hasPoster) {
    final showContentTypeBadge =
        item.contentType.toUpperCase() != item.tag.toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Poster + Quick Actions + Key Metrics (Fixed Width)
          SizedBox(
            width: 290,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Floating Poster Card (Overlapping Backdrop) - Tap to Expand Poster Lightbox
                Transform.translate(
                  offset: const Offset(0, -65),
                  child: Center(
                    child: Tooltip(
                      message: 'Tap to view full poster',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => ImageLightboxDialog.show(
                          context,
                          imageUrl: item.posterUrl ?? item.backdropUrl!,
                          title: item.title,
                          subtitle: 'Official Poster Artwork',
                          resolutionLabel: 'HD Poster (720×1080)',
                          fallbackGradient: item.gradient,
                          fallbackIcon: item.icon,
                        ),
                        child: Container(
                          width: 145,
                          height: 215,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                hasPoster
                                    ? AppCachedNetworkImage(
                                        imageUrl:
                                            item.posterUrl ?? item.backdropUrl!,
                                        fit: BoxFit.cover,
                                        fallbackGradient: item.gradient,
                                        fallbackIcon: item.icon,
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: item.gradient,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            item.icon,
                                            size: 50,
                                            color: Colors.white30,
                                          ),
                                        ),
                                      ),
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.zoom_in_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Transform.translate(
                  offset: const Offset(0, -45),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Action: Watch Now
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text(
                          'Watch Now',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        onPressed: _openPlayer,
                      ),

                      const SizedBox(height: 10),

                      // Action: Watchlist & Share
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                backgroundColor: _isInWatchlist
                                    ? theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.25)
                                    : null,
                              ),
                              icon: Icon(
                                _isInWatchlist
                                    ? Icons.bookmark_added_rounded
                                    : Icons.bookmark_add_outlined,
                                size: 19,
                                color: _isInWatchlist
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                              label: Text(
                                _isInWatchlist ? 'Saved' : 'Watchlist',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _isInWatchlist
                                      ? theme.colorScheme.primary
                                      : null,
                                ),
                              ),
                              onPressed: _toggleWatchlist,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.share_outlined, size: 19),
                            tooltip: 'Share / Copy Info',
                            onPressed: _shareMovie,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Quick Metrics 2x2 Grid Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricColumn(
                                    icon: Icons.star_rounded,
                                    iconColor: Colors.amber,
                                    title: '${item.rating}/10',
                                    subtitle: item.formattedVoteCount,
                                  ),
                                ),
                                _buildVerticalDivider(theme),
                                Expanded(
                                  child: _MetricColumn(
                                    icon: Icons.schedule_rounded,
                                    iconColor: theme.colorScheme.primary,
                                    title: item.formattedRuntime ??
                                        '${item.runtime ?? 'N/A'}m',
                                    subtitle: 'Runtime',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(
                              height: 1,
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricColumn(
                                    icon: Icons.calendar_today_rounded,
                                    iconColor: theme.colorScheme.tertiary,
                                    title: item.year,
                                    subtitle: 'Release',
                                  ),
                                ),
                                _buildVerticalDivider(theme),
                                Expanded(
                                  child: _MetricColumn(
                                    icon: Icons.local_fire_department_rounded,
                                    iconColor: Colors.deepOrangeAccent,
                                    title: item.popularity > 0
                                        ? item.popularity.toStringAsFixed(1)
                                        : 'N/A',
                                    subtitle: 'Popularity',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 28),

          // Right Column: Title, Badges, Overview, Specifications Grid
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Badges
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _Badge(
                      label: item.tag,
                      color: theme.colorScheme.primaryContainer,
                      textColor: theme.colorScheme.onPrimaryContainer,
                    ),
                    if (showContentTypeBadge)
                      _Badge(
                        label: item.contentType.toUpperCase(),
                        color: theme.colorScheme.secondaryContainer,
                        textColor: theme.colorScheme.onSecondaryContainer,
                      ),
                    if (item.adult)
                      _Badge(
                        label: '18+',
                        color: theme.colorScheme.errorContainer,
                        textColor: theme.colorScheme.onErrorContainer,
                      ),
                    _Badge(
                      label: item.status,
                      color: theme.colorScheme.surfaceContainerHighest,
                      textColor: theme.colorScheme.onSurfaceVariant,
                      icon: Icons.circle,
                      iconColor: Colors.greenAccent,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Movie Title
                Text(
                  item.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),

                // Original Title if different
                if (item.originalTitle != null &&
                    item.originalTitle!.isNotEmpty &&
                    item.originalTitle != item.title) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Original: ${item.originalTitle}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                // Tagline
                if (item.tagline != null && item.tagline!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '“${item.tagline}”',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Storyline & Overview
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 19,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Storyline & Overview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.overview,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.6,
                    fontSize: 14.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Movie Details & Specifications Card
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 19,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Movie Details & Specifications',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSpecificationsCard(theme, item, isWide: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Compact Mobile 1-Column Layout ---
  Widget _buildCompactLayout(ThemeData theme, MovieItem item, bool hasPoster) {
    final showContentTypeBadge =
        item.contentType.toUpperCase() != item.tag.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Poster & Title Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Transform.translate(
            offset: const Offset(0, -45),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Floating Poster Card - Tap to Expand Poster Lightbox
                Tooltip(
                  message: 'Tap to view full poster',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => ImageLightboxDialog.show(
                      context,
                      imageUrl: item.posterUrl ?? item.backdropUrl!,
                      title: item.title,
                      subtitle: 'Official Poster Artwork',
                      resolutionLabel: 'HD Poster (720×1080)',
                      fallbackGradient: item.gradient,
                      fallbackIcon: item.icon,
                    ),
                    child: Container(
                      width: 105,
                      height: 155,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            hasPoster
                                ? AppCachedNetworkImage(
                                    imageUrl:
                                        item.posterUrl ?? item.backdropUrl!,
                                    fit: BoxFit.cover,
                                    fallbackGradient: item.gradient,
                                    fallbackIcon: item.icon,
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient:
                                          LinearGradient(colors: item.gradient),
                                    ),
                                    child: Center(
                                      child: Icon(item.icon,
                                          size: 40, color: Colors.white30),
                                    ),
                                  ),
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.all(3.5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Icon(
                                  Icons.zoom_in_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Title, Tagline & Badges Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badges row
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Badge(
                            label: item.tag,
                            color: theme.colorScheme.primaryContainer,
                            textColor: theme.colorScheme.onPrimaryContainer,
                          ),
                          if (showContentTypeBadge)
                            _Badge(
                              label: item.contentType.toUpperCase(),
                              color: theme.colorScheme.secondaryContainer,
                              textColor:
                                  theme.colorScheme.onSecondaryContainer,
                            ),
                          if (item.adult)
                            _Badge(
                              label: '18+',
                              color: theme.colorScheme.errorContainer,
                              textColor: theme.colorScheme.onErrorContainer,
                            ),
                          _Badge(
                            label: item.status,
                            color: theme.colorScheme.surfaceContainerHighest,
                            textColor: theme.colorScheme.onSurfaceVariant,
                            icon: Icons.circle,
                            iconColor: Colors.greenAccent,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Movie Title
                      Text(
                        item.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 21,
                          height: 1.2,
                        ),
                      ),

                      // Original Title if different
                      if (item.originalTitle != null &&
                          item.originalTitle!.isNotEmpty &&
                          item.originalTitle != item.title) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.originalTitle!,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],

                      // Tagline
                      if (item.tagline != null && item.tagline!.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          '“${item.tagline}”',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Highlight Metrics Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MetricColumn(
                  icon: Icons.star_rounded,
                  iconColor: Colors.amber,
                  title: '${item.rating}/10',
                  subtitle: item.formattedVoteCount,
                ),
                _buildVerticalDivider(theme),
                _MetricColumn(
                  icon: Icons.schedule_rounded,
                  iconColor: theme.colorScheme.primary,
                  title: item.formattedRuntime ?? '${item.runtime ?? 'N/A'}m',
                  subtitle: 'Runtime',
                ),
                _buildVerticalDivider(theme),
                _MetricColumn(
                  icon: Icons.calendar_today_rounded,
                  iconColor: theme.colorScheme.tertiary,
                  title: item.year,
                  subtitle: item.formattedReleaseDate.length > 8
                      ? item.formattedReleaseDate.substring(0, 6)
                      : item.formattedReleaseDate,
                ),
                _buildVerticalDivider(theme),
                _MetricColumn(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: Colors.deepOrangeAccent,
                  title: item.popularity > 0
                      ? item.popularity.toStringAsFixed(1)
                      : 'N/A',
                  subtitle: 'Popularity',
                ),
              ],
            ),
          ),
        ),

        // Action Buttons Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Primary Watch Button
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text(
                    'Watch Now',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: _openPlayer,
                ),
              ),

              const SizedBox(width: 10),

              // Watchlist Button
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: _isInWatchlist
                        ? theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.25)
                        : null,
                  ),
                  icon: Icon(
                    _isInWatchlist
                        ? Icons.bookmark_added_rounded
                        : Icons.bookmark_add_outlined,
                    size: 20,
                    color: _isInWatchlist ? theme.colorScheme.primary : null,
                  ),
                  label: Text(
                    _isInWatchlist ? 'Saved' : 'Watchlist',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          _isInWatchlist ? theme.colorScheme.primary : null,
                    ),
                  ),
                  onPressed: _toggleWatchlist,
                ),
              ),

              const SizedBox(width: 10),

              // Share / Copy info Button
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.share_outlined, size: 20),
                tooltip: 'Share / Copy Info',
                onPressed: _shareMovie,
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Overview / Synopsis Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Storyline & Overview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.overview,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Specifications Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Movie Details & Specifications',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSpecificationsCard(theme, item, isWide: false),
            ],
          ),
        ),
      ],
    );
  }

  // --- Structured Specifications Card (Supports 2-column wide vs 1-column compact) ---
  Widget _buildSpecificationsCard(ThemeData theme, MovieItem item,
      {required bool isWide}) {
    if (isWide) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Specs Column
            Expanded(
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.title_rounded,
                    label: 'Original Title',
                    value: item.originalTitle?.isNotEmpty == true
                        ? item.originalTitle!
                        : item.title,
                  ),
                  _buildCardDivider(theme),
                  _DetailRow(
                    icon: Icons.movie_filter_rounded,
                    label: 'Format & Genre',
                    value: '${item.genre} (${item.contentType})',
                  ),
                  _buildCardDivider(theme),
                  _DetailRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Status',
                    value: item.status,
                  ),
                  _buildCardDivider(theme),
                  _DetailRow(
                    icon: Icons.event_available_rounded,
                    label: 'Release Date',
                    value: item.formattedReleaseDate,
                  ),
                  if (item.runtime != null && item.runtime! > 0) ...[
                    _buildCardDivider(theme),
                    _DetailRow(
                      icon: Icons.timer_outlined,
                      label: 'Duration',
                      value: item.formattedRuntime != null
                          ? '${item.formattedRuntime!} (${item.runtime}m)'
                          : '${item.runtime} minutes',
                    ),
                  ],
                  _buildCardDivider(theme),
                  _DetailRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Age Restriction',
                    value: item.adult
                        ? 'Adult (18+)'
                        : 'General Audiences',
                  ),
                ],
              ),
            ),

            const SizedBox(width: 18),
            Container(
              width: 1,
              height: 220,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
            ),
            const SizedBox(width: 18),

            // Right Specs Column
            Expanded(
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.stars_rounded,
                    label: 'User Rating',
                    value:
                        '${item.voteAverage > 0 ? item.voteAverage.toStringAsFixed(2) : item.rating} (${item.formattedFullVoteCount})',
                  ),
                  _buildCardDivider(theme),
                  _DetailRow(
                    icon: Icons.trending_up_rounded,
                    label: 'Popularity',
                    value: item.popularity > 0
                        ? item.popularity.toStringAsFixed(1)
                        : 'N/A',
                  ),
                  _buildCardDivider(theme),
                  _DetailRow(
                    icon: Icons.attach_money_rounded,
                    label: 'Budget',
                    value: MovieItem.formatFullCurrency(item.budget),
                  ),
                  _buildCardDivider(theme),
                  _DetailRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Box Office',
                    value: MovieItem.formatFullCurrency(item.revenue),
                  ),
                  if (item.imdbId != null && item.imdbId!.isNotEmpty) ...[
                    _buildCardDivider(theme),
                    _DetailRow(
                      icon: Icons.link_rounded,
                      label: 'IMDb ID',
                      value: item.imdbId!,
                      onCopy: () => _copyText('IMDb ID', item.imdbId!),
                    ),
                  ],
                  if (item.tmdbId != null) ...[
                    _buildCardDivider(theme),
                    _DetailRow(
                      icon: Icons.tag_rounded,
                      label: 'TMDB ID',
                      value: '#${item.tmdbId}',
                      onCopy: () => _copyText('TMDB ID', '${item.tmdbId}'),
                    ),
                  ],
                  if (item.homepage != null && item.homepage!.isNotEmpty) ...[
                    _buildCardDivider(theme),
                    _DetailRow(
                      icon: Icons.public_rounded,
                      label: 'Website',
                      value: item.homepage!,
                      isLink: true,
                      onCopy: () =>
                          _copyText('Homepage URL', item.homepage!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Compact single-column specs list
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.title_rounded,
            label: 'Original Title',
            value: item.originalTitle?.isNotEmpty == true
                ? item.originalTitle!
                : item.title,
          ),
          _buildCardDivider(theme),
          _DetailRow(
            icon: Icons.movie_filter_rounded,
            label: 'Format & Genre',
            value: '${item.genre} (${item.contentType})',
          ),
          _buildCardDivider(theme),
          _DetailRow(
            icon: Icons.check_circle_outline_rounded,
            label: 'Status',
            value: item.status,
          ),
          _buildCardDivider(theme),
          _DetailRow(
            icon: Icons.event_available_rounded,
            label: 'Release Date',
            value: item.formattedReleaseDate,
          ),
          if (item.runtime != null && item.runtime! > 0) ...[
            _buildCardDivider(theme),
            _DetailRow(
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: item.formattedRuntime != null
                  ? '${item.formattedRuntime!} (${item.runtime} minutes)'
                  : '${item.runtime} minutes',
            ),
          ],
          _buildCardDivider(theme),
          _DetailRow(
            icon: Icons.stars_rounded,
            label: 'User Rating',
            value:
                '${item.voteAverage > 0 ? item.voteAverage.toStringAsFixed(2) : item.rating} / 10 (${item.formattedFullVoteCount} votes)',
          ),
          _buildCardDivider(theme),
          _DetailRow(
            icon: Icons.trending_up_rounded,
            label: 'Popularity Score',
            value: item.popularity > 0
                ? item.popularity.toStringAsFixed(2)
                : 'N/A',
          ),
          _buildCardDivider(theme),
          _DetailRow(
            icon: Icons.attach_money_rounded,
            label: 'Budget',
            value: MovieItem.formatFullCurrency(item.budget),
          ),
          _buildCardDivider(theme),
          _DetailRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Revenue / Box Office',
            value: MovieItem.formatFullCurrency(item.revenue),
          ),
          if (item.numberOfSeasons != null ||
              item.numberOfEpisodes != null) ...[
            _buildCardDivider(theme),
            _DetailRow(
              icon: Icons.tv_rounded,
              label: 'Seasons & Episodes',
              value:
                  '${item.numberOfSeasons ?? 1} Seasons • ${item.numberOfEpisodes ?? 'N/A'} Episodes',
            ),
          ],
          if (item.lastAirDate != null && item.lastAirDate!.isNotEmpty) ...[
            _buildCardDivider(theme),
            _DetailRow(
              icon: Icons.live_tv_rounded,
              label: 'Last Air Date',
              value: item.lastAirDate!,
            ),
          ],
          _buildCardDivider(theme),
          _DetailRow(
            icon: Icons.verified_user_outlined,
            label: 'Age Restriction',
            value: item.adult
                ? 'Adult (18+)'
                : 'General Audiences (All Ages)',
          ),
          if (item.imdbId != null && item.imdbId!.isNotEmpty) ...[
            _buildCardDivider(theme),
            _DetailRow(
              icon: Icons.link_rounded,
              label: 'IMDb ID',
              value: item.imdbId!,
              onCopy: () => _copyText('IMDb ID', item.imdbId!),
            ),
          ],
          if (item.tmdbId != null) ...[
            _buildCardDivider(theme),
            _DetailRow(
              icon: Icons.tag_rounded,
              label: 'TMDB ID',
              value: '#${item.tmdbId}',
              onCopy: () => _copyText('TMDB ID', '${item.tmdbId}'),
            ),
          ],
          if (item.homepage != null && item.homepage!.isNotEmpty) ...[
            _buildCardDivider(theme),
            _DetailRow(
              icon: Icons.public_rounded,
              label: 'Official Website',
              value: item.homepage!,
              isLink: true,
              onCopy: () => _copyText('Homepage URL', item.homepage!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 32,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }

  Widget _buildCardDivider(ThemeData theme) {
    return Divider(
      height: 14,
      thickness: 1,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final Color? iconColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 7, color: iconColor ?? textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 10.5,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _MetricColumn({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLink;
  final VoidCallback? onCopy;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: isLink ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isLink
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontSize: 12,
              fontWeight: isLink ? FontWeight.w600 : FontWeight.w500,
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ),
        if (onCopy != null) ...[
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: onCopy,
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Icon(
                Icons.copy_rounded,
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
