import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_win_floating/webview_win_floating.dart';
import '../core/responsive.dart';
import '../core/stream_cleaner.dart';
import '../models/movie_item.dart';
import '../widgets/app_cached_image.dart';
import '../widgets/app_navigation_bar.dart';
import '../widgets/image_lightbox_dialog.dart';

class MoviePlayerScreen extends StatefulWidget {
  final MovieItem movie;

  const MoviePlayerScreen({
    super.key,
    required this.movie,
  });

  static Future<int?> open(BuildContext context, MovieItem movie) {
    return Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (context) => MoviePlayerScreen(movie: movie),
      ),
    );
  }

  @override
  State<MoviePlayerScreen> createState() => _MoviePlayerScreenState();
}

class _MoviePlayerScreenState extends State<MoviePlayerScreen> {
  WebViewController? _mobileController;
  WinWebViewController? _winController;

  bool _isLoading = true;
  int _loadingProgress = 0;
  bool _isWindows = false;
  String? _errorMessage;
  bool _isInWatchlist = false;

  String get _embedUrl {
    final id = widget.movie.tmdbId ?? widget.movie.id;
    if (widget.movie.contentType == 'TV Series' ||
        widget.movie.numberOfSeasons != null) {
      return 'https://vaplayer.ru/embed/tv/$id/1/1';
    }
    return 'https://vaplayer.ru/embed/movie/$id';
  }

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    try {
      if (!kIsWeb && Platform.isWindows) {
        _isWindows = true;
        final winCtrl = WinWebViewController();
        winCtrl.setJavaScriptMode(JavaScriptMode.unrestricted);
        winCtrl.setNavigationDelegate(
          WinNavigationDelegate(
            onNavigationRequest: (request) {
              if (StreamCleaner.isAllowedNavigation(request.url, _embedUrl)) {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
            onPageStarted: (url) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _loadingProgress = 100;
                });
              }
              StreamCleaner.apply(winController: winCtrl);
              Future.delayed(const Duration(milliseconds: 1000), () {
                StreamCleaner.apply(winController: winCtrl);
              });
              Future.delayed(const Duration(milliseconds: 2500), () {
                StreamCleaner.apply(winController: winCtrl);
              });
            },
            onProgress: (progress) {
              if (mounted) {
                setState(() => _loadingProgress = progress);
              }
              if (progress > 50) {
                StreamCleaner.apply(winController: winCtrl);
              }
            },
          ),
        );
        winCtrl.loadRequest(Uri.parse(_embedUrl));
        _winController = winCtrl;
      } else {
        _isWindows = false;
        final mobCtrl = WebViewController();
        _mobileController = mobCtrl;
        mobCtrl.setJavaScriptMode(JavaScriptMode.unrestricted);
        mobCtrl.setBackgroundColor(Colors.black);
        mobCtrl.setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              if (StreamCleaner.isAllowedNavigation(request.url, _embedUrl)) {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
            onProgress: (int progress) {
              if (mounted) {
                setState(() => _loadingProgress = progress);
              }
              if (progress > 50) {
                StreamCleaner.apply(mobileController: mobCtrl);
              }
            },
            onPageStarted: (String url) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _loadingProgress = 100;
                });
              }
              StreamCleaner.apply(mobileController: mobCtrl);
              Future.delayed(const Duration(milliseconds: 1000), () {
                StreamCleaner.apply(mobileController: mobCtrl);
              });
              Future.delayed(const Duration(milliseconds: 2500), () {
                StreamCleaner.apply(mobileController: mobCtrl);
              });
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
          ),
        );
        mobCtrl.loadRequest(Uri.parse(_embedUrl));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Native streaming plugin requires app restart.\nPlease re-run "flutter run -d windows" to compile native libraries.';
        });
      }
    }
  }

  void _reloadPlayer() {
    setState(() {
      _isLoading = true;
      _loadingProgress = 0;
    });
    if (_isWindows && _winController != null) {
      _winController!.reload();
    } else if (_mobileController != null) {
      _mobileController!.reload();
    }
  }

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
                    ? 'Added "${widget.movie.title}" to your Watchlist'
                    : 'Removed "${widget.movie.title}" from Watchlist',
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

  void _shareMovie() {
    final text = '${widget.movie.title} (${widget.movie.year})\n'
        'Rating: ${widget.movie.rating}/10\n'
        '${widget.movie.overview}\n'
        '${widget.movie.homepage ?? ''}';
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

  @override
  void dispose() {
    if (_isWindows && _winController != null) {
      _winController!.dispose();
    }
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, MovieItem movie) {
    return AppBar(
      backgroundColor: theme.colorScheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          size: 22,
        ),
        tooltip: 'Back',
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // CafeVerse Cinema Logo Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_cafe_rounded,
                  size: 16,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 5),
                Text(
                  'CafeVerse',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        movie.tag,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      movie.year,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isInWatchlist
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: _isInWatchlist
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          tooltip: _isInWatchlist
              ? 'Remove from Watchlist'
              : 'Add to Watchlist',
          onPressed: _toggleWatchlist,
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined, size: 20),
          tooltip: 'Share Movie',
          onPressed: _shareMovie,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 22),
          tooltip: 'Reload Stream',
          onPressed: _reloadPlayer,
        ),
        const SizedBox(width: 8),
      ],
      bottom: _isLoading
          ? PreferredSize(
              preferredSize: const Size.fromHeight(2.5),
              child: LinearProgressIndicator(
                value: _loadingProgress > 0 ? _loadingProgress / 100.0 : null,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
                minHeight: 2.5,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final movie = widget.movie;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscapeWide =
            constraints.maxWidth > constraints.maxHeight &&
            constraints.maxWidth >= Breakpoints.medium;

        final playerScaffold = Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: _buildAppBar(theme, movie),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscapeWide ? 24 : 14,
                vertical: isLandscapeWide ? 20 : 14,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Breakpoints.maxContentWidth,
                  ),
                  child: isLandscapeWide
                      ? _buildWideCinemaLayout(theme, movie)
                      : _buildCompactLayout(theme, movie),
                ),
              ),
            ),
          ),
          bottomNavigationBar: isLandscapeWide
              ? null
              : AppBottomNavBar(
                  selectedIndex: -1,
                  onDestinationSelected: (index) {
                    Navigator.of(context).pop(index);
                  },
                ),
        );

        if (isLandscapeWide) {
          return Scaffold(
            body: Row(
              children: [
                AppNavigationRail(
                  selectedIndex: -1,
                  onDestinationSelected: (index) {
                    Navigator.of(context).pop(index);
                  },
                  onLogoTap: () {
                    Navigator.of(context).pop(0);
                  },
                ),
                Expanded(child: playerScaffold),
              ],
            ),
          );
        }

        return playerScaffold;
      },
    );
  }

  // --- Wide Desktop / Cinema Layout (2 Columns) ---
  Widget _buildWideCinemaLayout(ThemeData theme, MovieItem movie) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: HD Video Player & Streaming Bar (Flex: 7)
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVideoPlayerCard(theme, movie),
              const SizedBox(height: 14),
              _buildStreamStatusControlBar(theme, movie),
            ],
          ),
        ),

        const SizedBox(width: 24),

        // Right Column: Movie Info & Overview Panel (Flex: 4)
        Expanded(
          flex: 4,
          child: _buildMovieInfoCard(theme, movie, isWide: true),
        ),
      ],
    );
  }

  // --- Compact Mobile / Portrait Layout (1 Column) ---
  Widget _buildCompactLayout(ThemeData theme, MovieItem movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVideoPlayerCard(theme, movie),
        const SizedBox(height: 12),
        _buildStreamStatusControlBar(theme, movie),
        const SizedBox(height: 16),
        _buildMovieInfoCard(theme, movie, isWide: false),
      ],
    );
  }

  // --- Video Player Viewport Container ---
  Widget _buildVideoPlayerCard(ThemeData theme, MovieItem movie) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: -4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            // Embedded Player Stream
            if (_errorMessage != null)
              Container(
                color: theme.colorScheme.surfaceContainerHigh,
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 44,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Restart Required',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: _reloadPlayer,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_isWindows && _winController != null)
              WinWebViewWidget(controller: _winController!)
            else if (!_isWindows && _mobileController != null)
              WebViewWidget(controller: _mobileController!)
            else
              const SizedBox.shrink(),

            // Loading Overlay
            if (_isLoading && _errorMessage == null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 38,
                            height: 38,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Streaming "${movie.title}"...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Connecting to CafeVerse cinema stream',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Top-right watermark click protection shield
            Positioned(
              top: 0,
              right: 0,
              width: 100,
              height: 60,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // Intercept and swallow taps to prevent opening watermark link
                },
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Stream Status & Quick Action Bar ---
  Widget _buildStreamStatusControlBar(ThemeData theme, MovieItem movie) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Live Pulse indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'HD STREAM',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              movie.contentType == 'TV Series' ? 'TV • S1 E1' : '1080p',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reload Stream', style: TextStyle(fontSize: 12)),
            onPressed: _reloadPlayer,
          ),
        ],
      ),
    );
  }

  // --- Movie Info & Overview Card ---
  Widget _buildMovieInfoCard(
    ThemeData theme,
    MovieItem movie, {
    required bool isWide,
  }) {
    final posterUrl = movie.posterUrl ?? movie.backdropUrl;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 20 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Movie Header: Poster Thumbnail + Title & Tagline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (posterUrl != null)
                GestureDetector(
                  onTap: () => ImageLightboxDialog.show(
                    context,
                    imageUrl: posterUrl,
                    title: movie.title,
                    subtitle: movie.tagline ?? movie.originalTitle,
                    resolutionLabel: 'HD Poster (720×1080)',
                    fallbackGradient: movie.gradient,
                    fallbackIcon: movie.icon,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: isWide ? 84 : 72,
                      height: isWide ? 122 : 104,
                      child: AppCachedNetworkImage(
                        imageUrl: posterUrl,
                        fit: BoxFit.cover,
                        fallbackGradient: movie.gradient,
                        fallbackIcon: movie.icon,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isWide ? 20 : 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (movie.originalTitle != null &&
                        movie.originalTitle != movie.title) ...[
                      const SizedBox(height: 2),
                      Text(
                        movie.originalTitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (movie.tagline != null && movie.tagline!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '"${movie.tagline!}"',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Rating Pill
                    if (movie.rating.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              movie.rating,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            Text(
                              '/10',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${movie.formattedVoteCount})',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Metadata Badges Wrap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge(
                theme: theme,
                icon: Icons.calendar_today_rounded,
                label: movie.formattedReleaseDate,
              ),
              if (movie.formattedRuntime != null)
                _buildBadge(
                  theme: theme,
                  icon: Icons.access_time_rounded,
                  label: movie.formattedRuntime!,
                ),
              _buildBadge(
                theme: theme,
                icon: Icons.category_rounded,
                label: movie.genre,
              ),
              _buildBadge(
                theme: theme,
                icon: Icons.tv_rounded,
                label: movie.contentType,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Synopsis Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Synopsis',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  movie.overview,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.55,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons: Watchlist & Share
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: _isInWatchlist
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHigh,
                  ),
                  icon: Icon(
                    _isInWatchlist
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_add_outlined,
                    size: 18,
                  ),
                  label: Text(
                    _isInWatchlist ? 'In Watchlist' : 'Add to Watchlist',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: _toggleWatchlist,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text(
                    'Share',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: _shareMovie,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required ThemeData theme,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
