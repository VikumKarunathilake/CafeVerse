import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_win_floating/webview_win_floating.dart';
import '../models/movie_item.dart';

class InlineMoviePlayer extends StatefulWidget {
  final MovieItem movie;
  final VoidCallback? onClose;

  const InlineMoviePlayer({
    super.key,
    required this.movie,
    this.onClose,
  });

  @override
  State<InlineMoviePlayer> createState() => _InlineMoviePlayerState();
}

class _InlineMoviePlayerState extends State<InlineMoviePlayer> {
  WebViewController? _mobileController;
  WinWebViewController? _winController;

  bool _isLoading = true;
  int _loadingProgress = 0;
  bool _isWindows = false;
  String? _errorMessage;

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
            },
            onProgress: (progress) {
              if (mounted) {
                setState(() => _loadingProgress = progress);
              }
            },
          ),
        );
        winCtrl.loadRequest(Uri.parse(_embedUrl));
        _winController = winCtrl;
      } else {
        _isWindows = false;
        final mobCtrl = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.black)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                if (mounted) {
                  setState(() => _loadingProgress = progress);
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
              },
              onWebResourceError: (WebResourceError error) {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              },
            ),
          )
          ..loadRequest(Uri.parse(_embedUrl));
        _mobileController = mobCtrl;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Native plugin requires restart. Please re-run "flutter run -d windows".';
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

  @override
  void dispose() {
    if (_isWindows && _winController != null) {
      _winController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final movie = widget.movie;

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // 1. Video WebView Player
          Positioned.fill(
            child: _errorMessage != null
                ? Container(
                    color: const Color(0xFF0F172A),
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : (_isWindows && _winController != null)
                    ? WinWebViewWidget(controller: _winController!)
                    : (!_isWindows && _mobileController != null)
                        ? WebViewWidget(controller: _mobileController!)
                        : const SizedBox.shrink(),
          ),

          // 2. Loading Indicator Overlay
          if (_isLoading && _errorMessage == null)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.75),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.8,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Streaming "${movie.title}"...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 3. Top Linear Progress bar
          if (_isLoading && _errorMessage == null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _loadingProgress > 0 ? _loadingProgress / 100.0 : null,
                backgroundColor: Colors.black,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
                minHeight: 2.5,
              ),
            ),

          // 4. Player Controls Top Bar
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                // Now Playing Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'STREAMING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Reload Stream Button
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(34, 34),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: 'Reload Stream',
                  onPressed: _reloadPlayer,
                ),
                const SizedBox(width: 8),

                // Close / Stop Player Button
                if (widget.onClose != null)
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(34, 34),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: 'Close Player',
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
