import 'package:flutter/material.dart';

class MovieItem {
  final int id;
  final int? tmdbId;
  final String? imdbId;
  final String title;
  final String? originalTitle;
  final String overview;
  final String? tagline;
  final String tag;
  final String rating;
  final double voteAverage;
  final int voteCount;
  final double popularity;
  final String year;
  final String releaseDate;
  final String status;
  final String contentType;
  final String genre;
  final int? runtime;
  final num? budget;
  final num? revenue;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final String? lastAirDate;
  final String? homepage;
  final String? slug;
  final bool adult;
  final String? backdropUrl;
  final String? posterUrl;
  final List<Color> gradient;
  final IconData icon;
  final bool isAnime;

  const MovieItem({
    required this.id,
    this.tmdbId,
    this.imdbId,
    required this.title,
    this.originalTitle,
    required this.overview,
    this.tagline,
    required this.tag,
    required this.rating,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.popularity = 0.0,
    required this.year,
    this.releaseDate = '',
    this.status = 'Released',
    this.contentType = 'Movie',
    required this.genre,
    this.runtime,
    this.budget,
    this.revenue,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.lastAirDate,
    this.homepage,
    this.slug,
    this.adult = false,
    this.backdropUrl,
    this.posterUrl,
    required this.gradient,
    required this.icon,
    required this.isAnime,
  });

  /// Formats runtime in minutes to '2h 16m' or '45m'
  String? get formattedRuntime {
    if (runtime == null || runtime! <= 0) return null;
    final hours = runtime! ~/ 60;
    final minutes = runtime! % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  /// Formats release date 'YYYY-MM-DD' to 'MMM d, yyyy'
  String get formattedReleaseDate {
    if (releaseDate.isEmpty) return 'N/A';
    try {
      final parts = releaseDate.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final month = int.tryParse(parts[1]) ?? 1;
        final day = int.tryParse(parts[2]) ?? 1;
        const monthNames = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final monthStr = (month >= 1 && month <= 12) ? monthNames[month - 1] : parts[1];
        return '$monthStr $day, $year';
      }
    } catch (_) {}
    return releaseDate;
  }

  /// Compact vote count e.g. '27.9K votes'
  String get formattedVoteCount {
    if (voteCount >= 1000000) {
      return '${(voteCount / 1000000).toStringAsFixed(1)}M votes';
    }
    if (voteCount >= 1000) {
      return '${(voteCount / 1000).toStringAsFixed(1)}K votes';
    }
    return '$voteCount votes';
  }

  /// Full comma separated vote count e.g. '27,929'
  String get formattedFullVoteCount {
    final str = voteCount.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  /// Compact currency format e.g. '$63.0M'
  static String? formatCurrency(num? amount) {
    if (amount == null || amount <= 0) return null;
    if (amount >= 1000000000) {
      return '\$${(amount / 1000000000).toStringAsFixed(1)}B';
    }
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\$$amount';
  }

  /// Full formatted currency with commas e.g. '$63,000,000'
  static String formatFullCurrency(num? amount) {
    if (amount == null || amount <= 0) return 'Not disclosed';
    final str = amount.toInt().toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '\$$formatted';
  }

  /// Whether the item has a valid backdrop image URL
  bool get hasBackdrop => backdropUrl != null && backdropUrl!.trim().isNotEmpty;

  /// Whether the item has a valid poster image URL
  bool get hasPoster => posterUrl != null && posterUrl!.trim().isNotEmpty;

  static const List<List<Color>> gradientPresets = [
    [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFFF416C), Color(0xFFFF4B2B)],
    [Color(0xFF1F4037), Color(0xFF99F2C8)],
    [Color(0xFF8A2387), Color(0xFFE94057)],
    [Color(0xFF0F2027), Color(0xFF2C5364)],
    [Color(0xFF2C3E50), Color(0xFFFD746C)],
    [Color(0xFF4B1248), Color(0xFFF0C27B)],
    [Color(0xFF000428), Color(0xFF004E92)],
    [Color(0xFF3A1C71), Color(0xFFD76D77)],
  ];

  static const List<IconData> iconPresets = [
    Icons.movie_rounded,
    Icons.animation_rounded,
    Icons.rocket_launch_rounded,
    Icons.nightlight_round,
    Icons.auto_awesome_rounded,
    Icons.stars_rounded,
    Icons.forest_rounded,
    Icons.flash_on_rounded,
    Icons.water_drop_rounded,
    Icons.speed_rounded,
  ];

  static String? _buildTmdbUrl(String? path, String size) {
    if (path == null) return null;
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('data:')) {
      return trimmed;
    }
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return 'https://image.tmdb.org/t/p/$size$cleanPath';
  }

  factory MovieItem.fromJson(
    Map<String, dynamic> map,
    int index, {
    String? defaultTag,
  }) {
    final id = (map['id'] as num?)?.toInt() ?? index;
    final tmdbId = (map['tmdbId'] as num?)?.toInt();
    final imdbId = (map['imdbId'] as String?)?.trim();
    final title = (map['title'] as String?)?.trim() ?? 'Untitled';
    final originalTitle = (map['originalTitle'] as String?)?.trim();
    final tagline = (map['tagline'] as String?)?.trim();
    final rawOverview = (map['overview'] as String?)?.trim() ?? '';
    final overview = rawOverview.isNotEmpty
        ? rawOverview
        : (tagline != null && tagline.isNotEmpty
            ? tagline
            : 'No description available.');
    final isAnime = map['isAnime'] == true;
    final rawContentType =
        (map['contentType'] as String?)?.trim().toLowerCase() ?? 'movie';
    final contentType = rawContentType == 'tv' ? 'TV Series' : 'Movie';
    final tag = defaultTag ??
        (isAnime ? 'ANIME' : (rawContentType == 'tv' ? 'SERIES' : 'MOVIE'));

    final voteAvg = (map['voteAverage'] as num?)?.toDouble() ?? 0.0;
    final rating = voteAvg > 0 ? voteAvg.toStringAsFixed(1) : '8.5';
    final voteCount = (map['voteCount'] as num?)?.toInt() ?? 0;
    final popularity = (map['popularity'] as num?)?.toDouble() ?? 0.0;

    final releaseDate = (map['releaseDate'] as String?)?.trim() ?? '';
    final year =
        releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '2026';

    final status = (map['status'] as String?)?.trim() ?? 'Released';
    final runtime = (map['runtime'] as num?)?.toInt();
    final budget = map['budget'] as num?;
    final revenue = map['revenue'] as num?;
    final numberOfSeasons = (map['numberOfSeasons'] as num?)?.toInt();
    final numberOfEpisodes = (map['numberOfEpisodes'] as num?)?.toInt();
    final lastAirDate = (map['lastAirDate'] as String?)?.trim();
    final homepage = (map['homepage'] as String?)?.trim();
    final slug = (map['slug'] as String?)?.trim();
    final adult = map['adult'] == true;

    // Comprehensive fallback for backdrop and poster keys (camelCase, snake_case, aliases)
    final backdropPath = (map['backdropPath'] ??
            map['backdrop_path'] ??
            map['backdrop'] ??
            map['backdropUrl'] ??
            map['backdrop_url'] ??
            map['background'] ??
            map['banner'] ??
            map['fanart']) as String?;

    final posterPath = (map['posterPath'] ??
            map['poster_path'] ??
            map['poster'] ??
            map['posterUrl'] ??
            map['poster_url'] ??
            map['cover'] ??
            map['image']) as String?;

    // backdropUrl max resolution limit: 1280x720 (TMDB w1280)
    final backdropUrl = _buildTmdbUrl(backdropPath, 'w1280');
    // posterUrl max resolution limit: 720x1080 (TMDB w780 HD poster standard)
    final posterUrl = _buildTmdbUrl(posterPath, 'w780');

    final genre = isAnime
        ? 'Anime'
        : (rawContentType == 'movie' ? 'Feature Film' : 'Series');
    final gradient = gradientPresets[index % gradientPresets.length];
    final icon = isAnime
        ? Icons.animation_rounded
        : iconPresets[index % iconPresets.length];

    return MovieItem(
      id: id,
      tmdbId: tmdbId,
      imdbId: imdbId,
      title: title,
      originalTitle: originalTitle,
      overview: overview,
      tagline: (tagline != null && tagline.isNotEmpty) ? tagline : null,
      tag: tag,
      rating: rating,
      voteAverage: voteAvg,
      voteCount: voteCount,
      popularity: popularity,
      year: year,
      releaseDate: releaseDate,
      status: status,
      contentType: contentType,
      genre: genre,
      runtime: runtime,
      budget: budget,
      revenue: revenue,
      numberOfSeasons: numberOfSeasons,
      numberOfEpisodes: numberOfEpisodes,
      lastAirDate: lastAirDate,
      homepage: (homepage != null && homepage.isNotEmpty) ? homepage : null,
      slug: slug,
      adult: adult,
      backdropUrl: backdropUrl,
      posterUrl: posterUrl,
      gradient: gradient,
      icon: icon,
      isAnime: isAnime,
    );
  }
}

