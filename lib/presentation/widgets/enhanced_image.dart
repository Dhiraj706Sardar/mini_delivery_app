import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';

/// Enhanced image widget with caching, placeholders, and error handling
class EnhancedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final IconData? placeholderIcon;
  final Color? placeholderColor;
  final bool showLoadingIndicator;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final Map<String, String>? httpHeaders;

  const EnhancedImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.placeholderIcon,
    this.placeholderColor,
    this.showLoadingIndicator = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.httpHeaders,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(AppTheme.radiusSm);

    // If no image URL provided, show placeholder
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(effectiveBorderRadius);
    }

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        httpHeaders: httpHeaders,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
        placeholder: (context, url) {
          return placeholder ?? _buildLoadingPlaceholder(effectiveBorderRadius);
        },
        errorWidget: (context, url, error) {
          return errorWidget ?? _buildErrorWidget(effectiveBorderRadius);
        },
      ),
    );
  }

  Widget _buildPlaceholder(BorderRadius borderRadius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: placeholderColor ?? AppTheme.surfaceVariant,
        borderRadius: borderRadius,
      ),
      child: Icon(
        placeholderIcon ?? Icons.restaurant,
        color: AppTheme.borderMedium,
        size: _getIconSize(),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BorderRadius borderRadius) {
    if (!showLoadingIndicator) {
      return _buildPlaceholder(borderRadius);
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: borderRadius,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            placeholderIcon ?? Icons.restaurant,
            color: AppTheme.borderLight,
            size: _getIconSize(),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BorderRadius borderRadius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: borderRadius,
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: AppTheme.errorColor,
            size: _getIconSize() * 0.8,
          ),
          if (height == null || height! > 60) ...[
            const SizedBox(height: 4),
            Text(
              'Failed to load',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  double _getIconSize() {
    if (width != null && height != null) {
      return (width! < height! ? width! : height!) * 0.4;
    } else if (width != null) {
      return width! * 0.4;
    } else if (height != null) {
      return height! * 0.4;
    }
    return 40.0;
  }
}

/// Restaurant image widget with specific styling
class RestaurantImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const RestaurantImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholderIcon: Icons.restaurant,
      placeholderColor: AppTheme.primaryColor.withValues(alpha: 0.1),
    );
  }
}

/// Menu item image widget with specific styling
class MenuItemImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const MenuItemImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholderIcon: Icons.fastfood,
      placeholderColor: AppTheme.secondaryColor.withValues(alpha: 0.1),
    );
  }
}

/// Avatar image widget for user profiles
class AvatarImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final IconData? fallbackIcon;
  final Color? backgroundColor;
  final Color? iconColor;

  const AvatarImage({
    super.key,
    this.imageUrl,
    this.size = 40,
    this.fallbackIcon,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppTheme.surfaceVariant,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? EnhancedImage(
                imageUrl: imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(size / 2),
                placeholderIcon: fallbackIcon ?? Icons.person,
                placeholderColor: backgroundColor ?? AppTheme.surfaceVariant,
              )
            : Icon(
                fallbackIcon ?? Icons.person,
                size: size * 0.6,
                color: iconColor ?? AppTheme.textSecondary,
              ),
      ),
    );
  }
}

/// Image gallery widget with hero animations
class ImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? heroTag;

  const ImageGallery({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          final imageUrl = imageUrls[index];

          return Center(
            child: Hero(
              tag: heroTag ?? imageUrl,
              child: InteractiveViewer(
                child: EnhancedImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  showLoadingIndicator: true,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Image with overlay gradient
class GradientOverlayImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final Widget? child;

  const GradientOverlayImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.gradient,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final defaultGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
    );

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Stack(
        children: [
          EnhancedImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            borderRadius: BorderRadius.zero,
          ),
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(gradient: gradient ?? defaultGradient),
          ),
          if (child != null) Positioned.fill(child: child!),
        ],
      ),
    );
  }
}
