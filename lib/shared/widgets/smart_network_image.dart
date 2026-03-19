import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A smart image widget that handles both SVG and raster images from network.
/// Automatically detects SVG URLs and uses the appropriate loader.
/// Uses cached_network_image for efficient caching and offline support.
class SmartNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;
  final Color? placeholderColor;
  final IconData placeholderIcon;

  const SmartNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorBuilder,
    this.loadingBuilder,
    this.placeholderColor,
    this.placeholderIcon = Icons.image_outlined,
  });

  bool get _isSvg {
    final lowerUrl = imageUrl.toLowerCase();
    // Check if URL ends with .svg (but not .svg.png which is a PNG)
    return lowerUrl.endsWith('.svg') && !lowerUrl.endsWith('.svg.png');
  }

  @override
  Widget build(BuildContext context) {
    // Handle empty or invalid URLs
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return _buildErrorWidget();
    }
    
    if (_isSvg) {
      return SvgPicture.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (context) => _buildPlaceholder(),
      );
    }

    // Use CachedNetworkImage for better caching and reliability
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => 
          errorBuilder?.call(context, error, null) ?? _buildErrorWidget(),
      // Cache settings for better performance
      memCacheWidth: width?.toInt() ?? 100,
      memCacheHeight: height?.toInt() ?? 100,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: (placeholderColor ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          placeholderIcon,
          size: (width ?? 24) * 0.5,
          color: placeholderColor?.withOpacity(0.5) ?? Colors.grey.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: (placeholderColor ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          placeholderIcon,
          size: (width ?? 24) * 0.5,
          color: placeholderColor ?? Colors.grey,
        ),
      ),
    );
  }
}

/// A circular avatar version of SmartNetworkImage for use in place of CircleAvatar
/// Uses cached_network_image for efficient caching.
class SmartNetworkAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Widget? fallbackChild;

  const SmartNetworkAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.fallbackChild,
  });

  bool get _isSvg {
    final lowerUrl = imageUrl.toLowerCase();
    return lowerUrl.endsWith('.svg') && !lowerUrl.endsWith('.svg.png');
  }

  @override
  Widget build(BuildContext context) {
    // Handle empty or invalid URLs
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey.shade200,
        child: fallbackChild ?? const Icon(Icons.person),
      );
    }
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey.shade200,
      child: ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: _isSvg
              ? SvgPicture.network(
                  imageUrl,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  placeholderBuilder: (_) => fallbackChild ?? const Icon(Icons.person),
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 150),
                  placeholder: (_, __) => Container(
                    color: backgroundColor ?? Colors.grey.shade200,
                    child: fallbackChild ?? const Icon(Icons.person),
                  ),
                  errorWidget: (_, __, ___) => fallbackChild ?? const Icon(Icons.person),
                ),
        ),
      ),
    );
  }
}

/// A brand logo widget that shows company/brand logos with fallback to initials.
/// Uses multiple logo sources for reliability.
class BrandLogo extends StatelessWidget {
  final String brandName;
  final String? logoUrl;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? fallbackIcon;
  final BorderRadius? borderRadius;

  const BrandLogo({
    super.key,
    required this.brandName,
    this.logoUrl,
    this.size = 40,
    this.backgroundColor,
    this.foregroundColor,
    this.fallbackIcon,
    this.borderRadius,
  });

  String get _initials {
    final words = brandName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words[0].isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  Color get _defaultBgColor {
    // Generate consistent color based on brand name
    final hash = brandName.hashCode;
    final colors = [
      const Color(0xFF2E4A9A), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Orange
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
      const Color(0xFF6366F1), // Indigo
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? _defaultBgColor;
    final fgColor = foregroundColor ?? Colors.white;
    final radius = borderRadius ?? BorderRadius.circular(8);
    
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
      ),
      child: Center(
        child: fallbackIcon != null
            ? Icon(fallbackIcon, color: fgColor, size: size * 0.5)
            : Text(
                _initials,
                style: TextStyle(
                  color: fgColor,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );

    // If no URL provided, show fallback
    if (logoUrl == null || logoUrl!.isEmpty || !logoUrl!.startsWith('http')) {
      return fallback;
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
        memCacheWidth: (size * 2).toInt(),
        memCacheHeight: (size * 2).toInt(),
      ),
    );
  }
}
