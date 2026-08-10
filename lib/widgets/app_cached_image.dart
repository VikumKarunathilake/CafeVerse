import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable cached network image widget that saves images to local disk cache,
/// displays a smooth shimmer placeholder during download, and handles errors gracefully.
class AppCachedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final List<Color>? fallbackGradient;
  final IconData? fallbackIcon;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget Function(BuildContext, String)? customPlaceholder;
  final Widget Function(BuildContext, String, dynamic)? customErrorWidget;

  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.fallbackGradient,
    this.fallbackIcon,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
    this.customPlaceholder,
    this.customErrorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) {
        if (customPlaceholder != null) {
          return customPlaceholder!(context, url);
        }
        return Shimmer.fromColors(
          baseColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.35 : 0.5,
          ),
          highlightColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.75 : 0.9,
          ),
          child: Container(
            width: width,
            height: height,
            color: theme.colorScheme.surfaceContainerHighest,
          ),
        );
      },
      errorWidget: (context, url, error) {
        if (customErrorWidget != null) {
          return customErrorWidget!(context, url, error);
        }
        if (fallbackGradient != null) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: fallbackGradient!,
              ),
            ),
            child: Center(
              child: Icon(
                fallbackIcon ?? Icons.broken_image_outlined,
                size: 40,
                color: Colors.white24,
              ),
            ),
          );
        }
        return Container(
          width: width,
          height: height,
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
          child: Center(
            child: Icon(
              fallbackIcon ?? Icons.broken_image_outlined,
              size: 36,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
            ),
          ),
        );
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
