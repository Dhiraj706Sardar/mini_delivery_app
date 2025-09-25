import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/restaurant/restaurant_bloc.dart';
import '../blocs/restaurant/restaurant_event.dart';
import '../blocs/restaurant/restaurant_state.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/loading_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/app_router.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  @override
  void initState() {
    super.initState();
    // Load restaurants when the screen is first created
    context.read<RestaurantBloc>().add(const LoadRestaurants());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Handle back button with cart preservation
        final shouldExit = await _handleBackButton(context);
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Restaurants'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading:
              false, // Remove back button since this is the home screen
        ),
        body: BlocBuilder<RestaurantBloc, RestaurantState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppTheme.primaryColor,
              child: _buildBody(state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(RestaurantState state) {
    if (state is RestaurantLoading) {
      return _buildLoadingState();
    } else if (state is RestaurantLoaded) {
      return _buildLoadedState(state);
    } else if (state is RestaurantError) {
      return _buildErrorState(state);
    } else {
      return _buildInitialState();
    }
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6, // Show 6 shimmer cards while loading
      itemBuilder: (context, index) {
        return const RestaurantCardShimmer();
      },
    );
  }

  Widget _buildLoadedState(RestaurantLoaded state) {
    if (state.restaurants.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = state.restaurants[index];
        return RestaurantCard(
          restaurant: restaurant,
          onTap: () => _onRestaurantTapped(restaurant.id),
        );
      },
    );
  }

  Widget _buildErrorState(RestaurantError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onRetryPressed,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: AppTheme.textLight),
            const SizedBox(height: 16),
            Text(
              'No Restaurants Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any restaurants at the moment. Please try again later.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onRetryPressed,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: AppTheme.textLight),
            const SizedBox(height: 16),
            Text(
              'Welcome to Food Delivery',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Discover amazing restaurants near you',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onLoadRestaurantsPressed,
              icon: const Icon(Icons.explore),
              label: const Text('Explore Restaurants'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    context.read<RestaurantBloc>().add(const RefreshRestaurants());

    // Wait for the refresh to complete
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _onRetryPressed() {
    context.read<RestaurantBloc>().add(const LoadRestaurants());
  }

  void _onLoadRestaurantsPressed() {
    context.read<RestaurantBloc>().add(const LoadRestaurants());
  }

  void _onRestaurantTapped(String restaurantId) {
    // Find the restaurant from the current state
    final state = context.read<RestaurantBloc>().state;
    if (state is RestaurantLoaded) {
      final restaurant = state.restaurants.firstWhere(
        (r) => r.id == restaurantId,
        orElse: () => throw Exception('Restaurant not found'),
      );

      // Select the restaurant in the bloc
      context.read<RestaurantBloc>().add(SelectRestaurant(restaurantId));

      // Navigate to menu screen with restaurant data
      Navigator.pushNamed(
        context,
        AppRoutes.menu,
        arguments: MenuScreenArguments(restaurant: restaurant),
      );
    }
  }

  Future<bool> _handleBackButton(BuildContext context) async {
    // Simple back button handling - can be enhanced later if needed
    return true;
  }
}
