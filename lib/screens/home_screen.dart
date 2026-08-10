import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/responsive.dart';
import '../models/movie_item.dart';
import '../widgets/category_chips.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/home_header.dart';
import '../widgets/movie_detail_sheet.dart';
import '../widgets/movie_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Trending',
    'Anime',
    'Sci-Fi',
    'Action',
    'Drama',
    'Fantasy',
  ];

  List<MovieItem> _featuredItems = [];
  List<MovieItem> _trendingItems = [];
  List<MovieItem> _topRatedItems = [];

  bool _isLoadingFeatured = true;
  bool _isLoadingTrending = true;
  bool _isLoadingTopRated = true;

  @override
  void initState() {
    super.initState();
    _fetchAllMovies();
  }

  Future<void> _fetchAllMovies() async {
    _fetchFeaturedItems();
    _fetchTrendingItems();
    _fetchTopRatedItems();
  }

  Future<void> _fetchFeaturedItems() async {
    try {
      final uri = Uri.parse(
        'https://cafeverce-api-nest.vercel.app/movies?limit=10&sortBy=createdAt',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body) as Map<String, dynamic>;
        final rawList = (jsonBody['data'] as List<dynamic>?) ?? [];
        final items = <MovieItem>[];
        for (int i = 0; i < rawList.length; i++) {
          items.add(
            MovieItem.fromJson(
              rawList[i] as Map<String, dynamic>,
              i,
              defaultTag: 'FEATURED',
            ),
          );
        }
        if (mounted) {
          setState(() {
            _featuredItems = items;
            _isLoadingFeatured = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingFeatured = false);
    }
  }

  Future<void> _fetchTrendingItems() async {
    try {
      final uri = Uri.parse(
        'https://cafeverce-api-nest.vercel.app/movies?limit=10&sortBy=popularity',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body) as Map<String, dynamic>;
        final rawList = (jsonBody['data'] as List<dynamic>?) ?? [];
        final items = <MovieItem>[];
        for (int i = 0; i < rawList.length; i++) {
          items.add(
            MovieItem.fromJson(rawList[i] as Map<String, dynamic>, i),
          );
        }
        if (mounted) {
          setState(() {
            _trendingItems = items;
            _isLoadingTrending = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingTrending = false);
    }
  }

  Future<void> _fetchTopRatedItems() async {
    try {
      final uri = Uri.parse(
        'https://cafeverce-api-nest.vercel.app/movies?limit=10&sortBy=voteAverage',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body) as Map<String, dynamic>;
        final rawList = (jsonBody['data'] as List<dynamic>?) ?? [];
        final items = <MovieItem>[];
        for (int i = 0; i < rawList.length; i++) {
          items.add(
            MovieItem.fromJson(
              rawList[i] as Map<String, dynamic>,
              i,
              defaultTag: 'TOP RATED',
            ),
          );
        }
        if (mounted) {
          setState(() {
            _topRatedItems = items;
            _isLoadingTopRated = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingTopRated = false);
    }
  }

  List<MovieItem> _getFilteredList(List<MovieItem> source) {
    if (_selectedCategory == 'All') return source;
    if (_selectedCategory == 'Anime') {
      return source.where((m) => m.isAnime).toList();
    }
    final filter = _selectedCategory.toLowerCase();
    return source.where((m) {
      return m.genre.toLowerCase().contains(filter) ||
          m.tag.toLowerCase().contains(filter) ||
          m.overview.toLowerCase().contains(filter);
    }).toList();
  }

  void _showMovieDetail(MovieItem item) {
    MovieDetailSheet.show(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= Breakpoints.medium;
            final horizontalPadding = (constraints.maxWidth * 0.025).clamp(
              16.0,
              40.0,
            );

            // Responsive hero banner height
            final double heroHeight;
            if (constraints.maxWidth >= 1400) {
              heroHeight = 420.0;
            } else if (constraints.maxWidth >= 1000) {
              heroHeight = 370.0;
            } else if (constraints.maxWidth >= 600) {
              heroHeight = 290.0;
            } else {
              heroHeight = 220.0;
            }

            // Card dimensions based on available width
            final double cardWidth;
            final double cardHeight;
            final double sectionHeight;

            if (constraints.maxWidth >= 1200) {
              cardWidth = 175.0;
              cardHeight = 265.0;
              sectionHeight = 275.0;
            } else if (constraints.maxWidth >= 700) {
              cardWidth = 160.0;
              cardHeight = 245.0;
              sectionHeight = 255.0;
            } else {
              cardWidth = 145.0;
              cardHeight = 225.0;
              sectionHeight = 235.0;
            }

            // Filter items based on selected category
            final trendingList = _getFilteredList(_trendingItems);
            final topRatedList = _getFilteredList(_topRatedItems);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  HomeHeader(horizontalPadding: horizontalPadding),

                  // Hero Featured Carousel
                  const SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: HeroCarousel(
                      items: _featuredItems,
                      isLoading: _isLoadingFeatured && _featuredItems.isEmpty,
                      height: heroHeight,
                      isWide: isWide,
                      onMovieTap: _showMovieDetail,
                    ),
                  ),

                  // Category Filter Chips
                  const SizedBox(height: 20),
                  CategoryChips(
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    horizontalPadding: horizontalPadding,
                    onCategorySelected: (category) {
                      setState(() => _selectedCategory = category);
                    },
                  ),

                  // Section: Trending Now
                  const SizedBox(height: 28),
                  MovieSection(
                    title: 'Trending Now',
                    emoji: '🔥',
                    items: trendingList,
                    horizontalPadding: horizontalPadding,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    sectionHeight: sectionHeight,
                    isLoading: _isLoadingTrending && _trendingItems.isEmpty,
                    onMovieTap: _showMovieDetail,
                  ),

                  // Section: Top Rated
                  const SizedBox(height: 32),
                  MovieSection(
                    title: 'Top Rated Masterpieces',
                    emoji: '⭐',
                    items: topRatedList,
                    horizontalPadding: horizontalPadding,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    sectionHeight: sectionHeight,
                    isLoading: _isLoadingTopRated && _topRatedItems.isEmpty,
                    onMovieTap: _showMovieDetail,
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
