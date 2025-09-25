import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

/// Loading widgets with shimmer effects
class LoadingWidgets {
  LoadingWidgets._();

  /// Restaurant card shimmer
  static Widget restaurantCardShimmer() {
    return Card(
      margin: const EdgeInsets.all(AppTheme.spaceSm),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Shimmer.fromColors(
          baseColor: AppTheme.surfaceVariant,
          highlightColor: AppTheme.surfaceColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Container(
                height: 16,
                width: double.infinity,
                color: AppTheme.surfaceVariant,
              ),
              const SizedBox(height: AppTheme.spaceXs),
              Container(
                height: 14,
                width: 150,
                color: AppTheme.surfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menu item card shimmer
  static Widget menuItemCardShimmer() {
    return Card(
      margin: const EdgeInsets.all(AppTheme.spaceSm),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Shimmer.fromColors(
          baseColor: AppTheme.surfaceVariant,
          highlightColor: AppTheme.surfaceColor,
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: AppTheme.surfaceVariant,
                    ),
                    const SizedBox(height: AppTheme.spaceXs),
                    Container(
                      height: 14,
                      width: 100,
                      color: AppTheme.surfaceVariant,
                    ),
                    const SizedBox(height: AppTheme.spaceXs),
                    Container(
                      height: 16,
                      width: 60,
                      color: AppTheme.surfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Cart item shimmer
  static Widget cartItemShimmer() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Shimmer.fromColors(
        baseColor: AppTheme.surfaceVariant,
        highlightColor: AppTheme.surfaceColor,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    color: AppTheme.surfaceVariant,
                  ),
                  const SizedBox(height: AppTheme.spaceXs),
                  Container(
                    height: 14,
                    width: 80,
                    color: AppTheme.surfaceVariant,
                  ),
                ],
              ),
            ),
            Container(
              width: 80,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generic loading indicator
  static Widget loadingIndicator({Color? color, double? size}) {
    return Center(
      child: SizedBox(
        width: size ?? 24,
        height: size ?? 24,
        child: CircularProgressIndicator(
          color: color ?? AppTheme.primaryColor,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

/// Restaurant card shimmer widget
class RestaurantCardShimmer extends StatelessWidget {
  const RestaurantCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingWidgets.restaurantCardShimmer();
  }
}

/// Menu item card shimmer widget
class MenuItemCardShimmer extends StatelessWidget {
  const MenuItemCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingWidgets.menuItemCardShimmer();
  }
}

/// Cart item shimmer widget
class CartItemShimmer extends StatelessWidget {
  const CartItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingWidgets.cartItemShimmer();
  }
}