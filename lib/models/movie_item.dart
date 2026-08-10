import 'package:flutter/material.dart';

class MovieItem {
  final int id;
  final String title;
  final String overview;
  final String tag;
  final String rating;
  final String year;
  final String genre;
  final String? backdropUrl;
  final String? posterUrl;
  final List<Color> gradient;
  final IconData icon;
  final bool isAnime;

  const MovieItem({
    required this.id,
    required this.title,
    required this.overview,
    required this.tag,
    required this.rating,
    required this.year,
    required this.genre,
    this.backdropUrl,
    this.posterUrl,
    required this.gradient,
    required this.icon,
    required this.isAnime,
  });

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

  factory MovieItem.fromJson(
    Map<String, dynamic> map,
    int index, {
    String? defaultTag,
  }) {
    final id = (map['id'] as num?)?.toInt() ?? index;
    final title = (map['title'] as String?)?.trim() ?? 'Untitled';
    final tagline = (map['tagline'] as String?)?.trim();
    final overview = (map['overview'] as String?)?.trim() ?? '';
    final summary = (tagline != null && tagline.isNotEmpty)
        ? tagline
        : (overview.isNotEmpty ? overview : 'No description available.');
    final isAnime = map['isAnime'] == true;
    final contentType =
        (map['contentType'] as String?)?.toUpperCase() ?? 'MOVIE';
    final tag = defaultTag ?? (isAnime ? 'ANIME' : contentType);

    final voteAvg = (map['voteAverage'] as num?)?.toDouble() ?? 0.0;
    final rating = voteAvg > 0 ? voteAvg.toStringAsFixed(1) : '8.5';

    final releaseDate = (map['releaseDate'] as String?) ?? '';
    final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '2026';

    final backdropPath = map['backdropPath'] as String?;
    final posterPath = map['posterPath'] as String?;
    final backdropUrl = (backdropPath != null && backdropPath.isNotEmpty)
        ? 'https://image.tmdb.org/t/p/w780$backdropPath'
        : null;
    final posterUrl = (posterPath != null && posterPath.isNotEmpty)
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : null;

    final genre = isAnime
        ? 'Anime'
        : (contentType.toLowerCase() == 'movie' ? 'Feature Film' : 'Series');
    final gradient = gradientPresets[index % gradientPresets.length];
    final icon = isAnime
        ? Icons.animation_rounded
        : iconPresets[index % iconPresets.length];

    return MovieItem(
      id: id,
      title: title,
      overview: summary,
      tag: tag,
      rating: rating,
      year: year,
      genre: genre,
      backdropUrl: backdropUrl,
      posterUrl: posterUrl,
      gradient: gradient,
      icon: icon,
      isAnime: isAnime,
    );
  }
}
