import 'package:equatable/equatable.dart';

/// Base class for all restaurant-related events
abstract class RestaurantEvent extends Equatable {
  const RestaurantEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load the list of restaurants
class LoadRestaurants extends RestaurantEvent {
  const LoadRestaurants();
}

/// Event to select a specific restaurant
class SelectRestaurant extends RestaurantEvent {
  final String restaurantId;

  const SelectRestaurant(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

/// Event to refresh the restaurant list
class RefreshRestaurants extends RestaurantEvent {
  const RefreshRestaurants();
}